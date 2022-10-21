// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { IWormhole } from '../interfaces/Wormhole/IWormhole.sol';

interface IMockWormhole is IWormhole {
    function createDummyVM(
        uint16 chainId,
        bytes32 emitterAddress,
        bytes memory payload
    ) external pure returns (bytes memory vm);
}
