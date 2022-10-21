// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SettlementStructs {
    struct Settlement {
        // PayloadID uint8 = 8 (just some arbitrary I picked)
        uint8 payloadID;

        // Settlement status on this chain
        // 1: success (from mesh chains)
        // 2: fail (from mesh chains)
        uint8 status;

        // Token ID used in this settlement
        uint256 tokenId;

        // Execution data on final state settlement
        bytes execution;
    }
}
