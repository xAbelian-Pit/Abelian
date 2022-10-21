// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import 'hardhat/console.sol';

import { AbelianToken } from '../AbelianToken.sol';
import { MockWormhole } from './MockWormhole.sol';
import { IWormhole } from '../interfaces/Wormhole/IWormhole.sol';

contract MockAbelianToken is AbelianToken {
    MockWormhole _wormhole;

    constructor(uint16 _chainId) AbelianToken(address(0)) {
        console.log('Initialized MockDotRegistry');
        _wormhole = new MockWormhole(_chainId);
    }

    function wormhole() public view override returns (IWormhole) {
        return _wormhole;
    }
}
