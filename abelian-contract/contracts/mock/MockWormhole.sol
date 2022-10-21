// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import 'hardhat/console.sol';

import { IMockWormhole } from './IMockWormhole.sol';
import { Structs } from '../interfaces/Wormhole/Structs.sol';
import { BytesLib } from '../libs/BytesLib.sol';

contract MockWormhole is IMockWormhole {
    using BytesLib for bytes;

    event MockVMLog(bytes vm);

    uint16 private immutable _chainId;

    constructor(uint16 cid) {
        // console.log('Initialized MockWormhole');
        _chainId = cid;
    }

    /// @dev Publish a message to be attested by the Wormhole network
    /// NOTE: https://github.com/wormhole-foundation/wormhole/blob/dev.v2/ethereum/contracts/Implementation.sol#L15
    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) public payable returns (uint64 sequence) {
        sequence = 0;
        // console.log('publishing message...');
        emit LogMessagePublished(msg.sender, sequence, nonce, payload, consistencyLevel);

//        console.log('Publish message emitterAddress');
//        console.logBytes32(bytes32(uint256(uint160(msg.sender))));
        bytes memory vm = createDummyVM(_chainId, bytes32(uint256(uint160(msg.sender))), payload);
        emit MockVMLog(vm);
//        console.logBytes(vm);
    }

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason) {
        vm = parseVM(encodedVM);
        // (valid, reason) = verifyVM(vm);
        valid = true;
        reason = '';
//        console.log(vm.emitterChainId);
//        console.logBytes32(vm.emitterAddress);
    }

    function verifyVM(Structs.VM memory vm) external view returns (bool valid, string memory reason) {
        valid = true;
        reason = '';
    }

    function verifySignatures(
        bytes32 hash,
        Structs.Signature[] memory signatures,
        Structs.GuardianSet memory guardianSet
    ) external pure returns (bool valid, string memory reason) {
        valid = true;
        reason = '';
    }

    function getGuardianSet(uint32 index) external view returns (Structs.GuardianSet memory) {
        address[] memory s;
        s[0] = address(0);
        return Structs.GuardianSet({
            keys: s,
            expirationTime: uint32(block.timestamp + 6000)
        });
    }

    function getCurrentGuardianSetIndex() external view returns (uint32) {
        return 0;
    }

    function getGuardianSetExpiry() external view returns (uint32) {
        return uint32(block.timestamp + 6000);
    }

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool) {
        return true;
    }

    function isInitialized(address impl) external view returns (bool) {
        return true;
    }

    function chainId() external view returns (uint16) {
        // Assume sending from Ethereum
        return _chainId;
    }

    function governanceChainId() external view returns (uint16) {
        return 0;
    }

    function governanceContract() external view returns (bytes32) {
        return bytes32(0);
    }

    function messageFee() external view returns (uint256) {
        return 0;
    }

    function parseVM(bytes memory encodedVM) public pure virtual returns (Structs.VM memory vm) {
        uint index = 0;

        vm.version = encodedVM.toUint8(index);
        index += 1;
        // SECURITY: Note that currently the VM.version is not part of the hash
        // and for reasons described below it cannot be made part of the hash.
        // This means that this field's integrity is not protected and cannot be trusted.
        // This is not a problem today since there is only one accepted version, but it
        // could be a problem if we wanted to allow other versions in the future.
        require(vm.version == 1, 'VM version incompatible');

        vm.guardianSetIndex = encodedVM.toUint32(index);
        index += 4;

        // Parse Signatures
        uint256 signersLen = encodedVM.toUint8(index);
        index += 1;
        vm.signatures = new Structs.Signature[](signersLen);
        for (uint i = 0; i < signersLen; i++) {
            vm.signatures[i].guardianIndex = encodedVM.toUint8(index);
            index += 1;

            vm.signatures[i].r = encodedVM.toBytes32(index);
            index += 32;
            vm.signatures[i].s = encodedVM.toBytes32(index);
            index += 32;
            vm.signatures[i].v = encodedVM.toUint8(index) + 27;
            index += 1;
        }

        /*
        Hash the body
        SECURITY: Do not change the way the hash of a VM is computed!
        Changing it could result into two different hashes for the same observation.
        But xDapps rely on the hash of an observation for replay protection.
        */
        bytes memory body = encodedVM.slice(index, encodedVM.length - index);
        vm.hash = keccak256(abi.encodePacked(keccak256(body)));

        // Parse the body
        vm.timestamp = encodedVM.toUint32(index);
        index += 4;

        vm.nonce = encodedVM.toUint32(index);
        index += 4;

        vm.emitterChainId = encodedVM.toUint16(index);
        index += 2;

        vm.emitterAddress = encodedVM.toBytes32(index);
        index += 32;

        vm.sequence = encodedVM.toUint64(index);
        index += 8;

        vm.consistencyLevel = encodedVM.toUint8(index);
        index += 1;

        vm.payload = encodedVM.slice(index, encodedVM.length - index);
    }

    function createDummyVM(
        uint16 chainId,
        bytes32 emitterAddress,
        bytes memory payload
    ) public pure override returns (bytes memory vm) {
        vm = abi.encodePacked(
            // header
            uint8(1), // version
            uint32(1), // guardianSetIndex
            uint8(0), // signersLen ==> no sigs in mock vm
            // body
            uint32(1), // timestamp
            uint32(1), // nonce
            chainId, // emitterChainId
            emitterAddress, // emitterAddress
            uint64(0), // sequence
            uint8(1), // consistencyLevel
            payload // payload (can be any length)
        );
    }
}
