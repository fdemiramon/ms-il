// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Transaction Struct
/// @notice Defines the structure for multisig transactions
struct Transaction {
    address to;
    bytes data;
    bool isExecuted;
    address[] voters;
}
