// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import 'hardhat/console.sol';
import { Ownable } from '@klaytn/contracts/access/Ownable.sol';

import { AbelianKIP17 } from './AbelianKIP17.sol';
import { IWormhole } from './interfaces/Wormhole/IWormhole.sol';
import { BytesLib } from './libs/BytesLib.sol';
import { SettlementStructs } from './structs/SettlementStructs.sol';

contract AbelianToken is AbelianKIP17, Ownable {
    using BytesLib for bytes;

    event MetadataUpdate(
        address indexed owner,
        address indexed caller,
        uint256 indexed tokenId,
        string metadata
    );

    address public immutable CORE_BRIDGE_ADDRESS;

    uint256 public tokenIdCounter;

    mapping(uint256 => string) public tokenMetadata;

    /// @dev Pending state update settlements
    /// @dev tokenId => action hash (random order)
    mapping(uint256 => bytes32[]) public pending;

    /// @dev Pending state update settlements status (from other chains)
    /// @dev (tokenId & action) hash => chain id => settled state
    mapping(bytes32 => mapping(uint16 => bool)) public pendingSettlement;

    /// @dev (tokenId & action) hash => execution data
    mapping(bytes32 => bytes) private settlementExecution;

    // Supported Wormhole chain IDs
    // NOTE: Only EVMs for now... I need to learn Anchor...
    // uint16[] private chainIds = [2, 5, 6];
    uint16[] public chainIds = [2, 5, 6, 13];

    /// @dev Contract address (Wormhole-format) of deployed DotRegistry on other chains
    mapping(bytes32 => bool) public registryDelegates;

    uint32 private _nonce = 0;

    modifier onlyOwnerOrOperatorOfTokenId(uint256 tokenId) {
        require(
            ownerOf(tokenId) == msg.sender
            || (ownerOf(tokenId) != address(0) && isApprovedForAll(ownerOf(tokenId), msg.sender)),
            'Only owner of token ID allowed'
        );
        _;
    }

    constructor(address _coreBridgedAddress) {
        CORE_BRIDGE_ADDRESS = _coreBridgedAddress;
        _name = 'AbelianToken';
        _symbol = 'ABT';
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");
        return tokenMetadata[tokenId];
    }

    function updateMetadata(uint256 tokenId, string memory metadata) public onlyOwnerOrOperatorOfTokenId(tokenId) {
        require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");

        bytes memory execution = abi.encodeWithSignature('_updateMetadataFinalized(uint256,string)', tokenId, metadata);

        initializeStateSettlement(tokenId, execution);
    }

    function _updateMetadataFinalized(
        uint256 tokenId,
        string memory metadata
    ) internal {
        tokenMetadata[tokenId] = metadata;

        emit MetadataUpdate({
            owner: ownerOf(tokenId),
            caller: msg.sender,
            tokenId: tokenId,
            metadata: metadata
        });
    }

    function mint() public returns (uint256) {
        tokenIdCounter++;
        _mint(msg.sender, tokenIdCounter);
        return tokenIdCounter;
    }

    function _mint(
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(to != address(0), "KIP17: mint to the zero address");
        require(!_exists(tokenId), "KIP17: token already minted");

        // placeholder mint
        _balances[owner()] += 1;
        _owners[tokenId] = owner();

        bytes memory execution = abi.encodeWithSignature('_mintFinalized(address,uint256)', to, tokenId);

        initializeStateSettlement(tokenId, execution);
    }

    function _mintFinalized(
        address to,
        uint256 tokenId
    ) private {
        require(_balances[owner()] > 0, 'Balance error');
        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[owner()] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(ownerOf(tokenId) == from, "KIP17: transfer from incorrect owner");
        require(to != address(0), "KIP17: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[owner()] += 1;
        _owners[tokenId] = owner();

        bytes memory execution = abi.encodeWithSignature('_transferFinalized(address,address,uint256)', from, to, tokenId);

        initializeStateSettlement(tokenId, execution);
    }

    function _transferFinalized(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(_balances[owner()] > 0, 'Balance error');
        _beforeTokenTransfer(from, to, tokenId);

        _balances[owner()] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    function setRegistryDelegate(address[] memory delegates, bool[] memory permitted) external onlyOwner {
        require(delegates.length == permitted.length, 'Length mismatch');
        for (uint i = 0; i < delegates.length;) {
            require(delegates[i] != address(0));
            registryDelegates[addressToBytes32(delegates[i])] = permitted[i];
            unchecked {
                i++;
            }
        }
    }

    function addSupportedChainId(uint16 chainId) external onlyOwner {
        for (uint i = 0; i < chainIds.length;) {
            if (chainIds[i] == chainId) return;
            unchecked {
                i++;
            }
        }
        chainIds.push(chainId);
    }

    function removeSupportedChainId(uint16 chainId) external onlyOwner {
        for (uint i = 0; i < chainIds.length;) {
            if (chainIds[i] == chainId) {
                chainIds[i] = chainIds[chainIds.length - 1];
                chainIds.pop();
                return;
            }
            unchecked {
                i++;
            }
        }
    }

    function initializeStateSettlement(
        uint256 tokenId,
        bytes memory execution
    ) internal onlyOwnerOrOperatorOfTokenId(tokenId) returns (uint256 sequence) {
        SettlementStructs.Settlement memory settlement = SettlementStructs.Settlement({
            payloadID: 8,
            status: 1,
            tokenId: tokenId,
            execution: execution
        });
        // console.log(tokenId);
        // console.logBytes(execution);

        // two Benjamins for instant finality in testnet
        sequence = wormhole().publishMessage(_nonce, encodeSettlement(settlement), 200);
        // console.log(sequence);
        _nonce += 1;
    }

    function updateStateSettlement(bytes calldata encodedVM) public returns (uint64 sequence) {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(encodedVM);
        require(valid, reason);

        // NOTE: Reject VAA from own contract (this chain)
        require(registryDelegates[vm.emitterAddress], 'Unregistered delegate registry emitter address');

        SettlementStructs.Settlement memory settlement = _decodeVaaPayload(vm.payload);
        bytes32 _tie = tie(settlement.tokenId, settlement.execution);

        if (settlement.status == 1) {
            // receiving VM message from another chain that verifies there's no conflict on its chain
            pendingSettlement[_tie][vm.emitterChainId] = true;
        }

        if (isSettlementResolvedForAll(settlement.tokenId, settlement.execution)) {
            // All chains have verified that there's no conflict on their chain
            finalizeStateSettlement(settlement.tokenId, settlement.execution);
        } else if (!pendingSettlement[_tie][wormhole().chainId()]) {
            SettlementStructs.Settlement memory res = SettlementStructs.Settlement({
                payloadID: 8,
                status: 1,
                tokenId: settlement.tokenId,
                execution: settlement.execution
            });

            pendingSettlement[_tie][wormhole().chainId()] = true;
            if (settlementExecution[_tie].length == 0) { // empty
                settlementExecution[_tie] = settlement.execution;
            }

            // two-hunnet for instant finality in testnet
            sequence = wormhole().publishMessage(_nonce, encodeSettlement(res), 200);
            _nonce += 1;
        }
    }

    /// TODO: Finalize state in the order of requested timestamp from (multiple) chain/s
    function finalizeStateSettlement(
        uint256 tokenId,
        bytes memory execution
    ) internal {
        delete settlementExecution[tie(tokenId, execution)];

        removePending(tokenId, execution);

        (bool success,) = address(this).call(execution);
        require(success, 'Finalizing state failed');
    }

    function getChainIds() public view returns (uint16[] memory) {
        return chainIds;
    }

    function isSettlementResolvedForAll(uint256 tokenId, bytes memory execution) internal view returns (bool) {
        bytes32 _tie = tie(tokenId, execution);
        for (uint i = 0; i < chainIds.length;) {
            // don't return false if it's checking self chain ID
            if (chainIds[i] != wormhole().chainId() && !pendingSettlement[_tie][chainIds[i]]) return false;
            unchecked {
                i++;
            }
        }
        return true;
    }

    function removePending(uint256 tokenId, bytes memory execution) internal {
        bytes32 _tie = tie(tokenId, execution);

        // doesn't preserve order in the pending array
        for (uint i = 0; i < pending[tokenId].length;) {
            if (pending[tokenId][i] == _tie) {
                pending[tokenId][i] = pending[tokenId][pending[tokenId].length - 1];
                break;
            }
            unchecked {
                i++;
            }
        }

        // remove pending from the settlement period
        for (uint i = 0; i < chainIds.length;) {
            pendingSettlement[_tie][chainIds[i]] = false;
            unchecked {
                i++;
            }
        }
    }

    function wormhole() public virtual view returns (IWormhole) {
        return IWormhole(CORE_BRIDGE_ADDRESS);
    }

    function _decodeVaaPayload(bytes memory payload) private pure returns (SettlementStructs.Settlement memory) {
        SettlementStructs.Settlement memory decoded = SettlementStructs.Settlement({
            payloadID: payload.slice(0,1).toUint8(0),
            status: payload.slice(1,1).toUint8(0),
            tokenId: payload.slice(2,32).toUint256(0),
            execution: payload.slice(34, payload.length-34)
        });
        return decoded;
    }

    function encodeSettlement(SettlementStructs.Settlement memory reg) public pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(
            reg.payloadID,
            reg.status,
            reg.tokenId,
            reg.execution
        );
    }

    function bytes32ToAddress(bytes32 bys) private pure returns (address) {
        return address(uint160(uint256(bys)));
    }

    function addressToBytes32(address addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(addr))); // address is 20 bytes, so pad left 12 bytes (== ethers.utils.hexZeroPad(addr, 32))
    }

    /// @dev Token ID & Execution hashed
    function tie(uint256 tokenId, bytes memory execution) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, execution));
    }
}
