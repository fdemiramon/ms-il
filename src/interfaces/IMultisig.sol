// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IMultisig Interface
/// @notice Interface for the main Multisig functionality
interface IMultisig {
    event TransactionProposed(
        uint256 indexed transactionIndex, address indexed proposer, address indexed to, bytes data
    );

    event TransactionVoted(uint256 indexed transactionIndex, address indexed voter);

    event TransactionExecuted(uint256 indexed transactionIndex);

    function proposeTransaction(address to, bytes calldata data) external;
    function voteForTransaction(uint256 transactionIndex) external;
    function executeTransaction(uint256 transactionIndex) external;
}
