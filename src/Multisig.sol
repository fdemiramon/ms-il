// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./structs/Transaction.sol";
import "./interfaces/IMultisig.sol";

/// @title MS-IL
/// @notice A simple multisig wallet implementation
/// @dev This implementation is not secure and should not be used in production
contract Multisig is IMultisig {
    /* -------------------- */
    /* 1. CONSTANTS         */
    /* -------------------- */
    // none

    /* -------------------- */
    /* 2. IMMUTABLE         */
    /* -------------------- */
    // none

    /* -------------------- */
    /* 3. TRANSIENT STORAGE */
    /* -------------------- */
    // none

    /* -------------------- */
    /* 4. STRUCT            */
    /* -------------------- */
    // none

    /* -------------------- */
    /* 5. STORAGE           */
    /* -------------------- */

    /// @notice List of addresses that can vote on transactions
    /// @dev Cannot contain duplicates or zero address
    address[] public owners;

    /// @notice Number of votes required to execute a transaction
    /// @dev Must be > 0 and <= number of owners
    uint8 public threshold;

    /// @notice Array of all proposed transactions
    /// @dev Transactions are stored sequentially and referenced by index
    Transaction[] public transactions;

    /* -------------------- */
    /* 6. EVENTS            */
    /* -------------------- */
    // Events defined in IMultisig interface

    /* -------------------- */
    /* 7. CUSTOM ERRORS     */
    /* -------------------- */

    /// @notice Thrown when attempting to add zero address as owner
    error ZeroAddressOwner();
    /// @notice Thrown when attempting to add duplicate owner
    error DuplicateOwner(address owner);
    /// @notice Thrown when attempting to interact with executed transaction
    error TransactionAlreadyExecuted();
    /// @notice Thrown when non-owner attempts owner-only operation
    error NotAnOwner();
    /// @notice Thrown when owner attempts to vote twice
    error AlreadyVoted();
    /// @notice Thrown when threshold is invalid (0 or > owners.length)
    error InvalidNumberOfConfirmationsRequired();
    /// @notice Thrown when accessing non-existent transaction
    error TransactionDoesNotExist();
    /// @notice Thrown when executing transaction with insufficient votes
    error NotEnoughVotes();
    /// @notice Thrown when transaction execution fails
    error TransactionFailed();
    /// @notice Thrown when adding an address that is already an owner
    error OwnerAlreadyExists();
    /// @notice Thrown when removing owner would make threshold impossible
    error CannotRemoveOwner();
    /// @notice Thrown when removing non-existent owner
    error OwnerDoesNotExist();

    /* -------------------- */
    /* 8. MODIFIERS         */
    /* -------------------- */

    /// @notice Restricts function to calls through executeTransaction
    /// @dev Used for admin functions that require multisig approval
    modifier onlyMultisig() {
        require(msg.sender == address(this), "Only the multisig contract can call this function");
        _;
    }

    /* -------------------- */
    /* 9. CONSTRUCTOR       */
    /* -------------------- */

    /// @notice Deploys the multisig contract
    /// @param _owners Initial list of owner addresses
    /// @param _threshold Number of required votes to execute transactions
    /// @dev Validates owner list and threshold
    constructor(address[] memory _owners, uint8 _threshold) {
        if (_threshold == 0) {
            revert InvalidNumberOfConfirmationsRequired();
        }
        if (_threshold > _owners.length) {
            revert InvalidNumberOfConfirmationsRequired();
        }

        // Check for zero addresses and duplicates
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0)) {
                revert ZeroAddressOwner();
            }

            // Check for duplicates
            for (uint256 j = i + 1; j < _owners.length; j++) {
                if (owner == _owners[j]) {
                    revert DuplicateOwner(owner);
                }
            }
        }

        owners = _owners;
        threshold = _threshold;
    }

    /* -------------------- */
    /* 10a. WRITE FUNCTIONS */
    /* TX Lifecycle         */
    /* -------------------- */

    /// @notice Creates a new transaction proposal
    /// @param to Address that will receive the transaction
    /// @param data The calldata to be executed
    /// @dev Anyone can propose a transaction
    function proposeTransaction(address to, bytes calldata data) public {
        Transaction memory transaction = Transaction({to: to, data: data, isExecuted: false, voters: new address[](0)});
        transactions.push(transaction);
        emit TransactionProposed(transactions.length - 1, msg.sender, to, data);
    }

    /// @notice Records a vote for a transaction
    /// @param transactionIndex Index of the transaction in the transactions array
    /// @dev Only owners can vote, each only once, and not on executed transactions
    function voteForTransaction(uint256 transactionIndex) public {
        if (transactions[transactionIndex].isExecuted) {
            revert TransactionAlreadyExecuted();
        }

        bool isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }

        if (!isOwner) {
            revert NotAnOwner();
        }

        for (uint256 i = 0; i < transactions[transactionIndex].voters.length; i++) {
            if (transactions[transactionIndex].voters[i] == msg.sender) {
                revert AlreadyVoted();
            }
        }

        transactions[transactionIndex].voters.push(msg.sender);
        emit TransactionVoted(transactionIndex, msg.sender);
    }

    /// @notice Executes a transaction that has met the threshold
    /// @param transactionIndex Index of the transaction to execute
    /// @dev Anyone can execute once threshold is met
    function executeTransaction(uint256 transactionIndex) public {
        if (transactions[transactionIndex].isExecuted) {
            revert TransactionAlreadyExecuted();
        }

        if (transactions[transactionIndex].voters.length < threshold) {
            revert NotEnoughVotes();
        }

        (bool success,) = transactions[transactionIndex].to.call(transactions[transactionIndex].data);
        if (!success) {
            revert TransactionFailed();
        }
        transactions[transactionIndex].isExecuted = true;
        emit TransactionExecuted(transactionIndex);
    }

    /* -------------------- */
    /* 10b. WRITE FUNCTIONS */
    /* Admin Functions      */
    /* -------------------- */

    /// @notice Changes the number of required votes
    /// @param newThreshold New threshold value
    /// @dev Must be called through multisig, cannot exceed owners length
    function setThreshold(uint8 newThreshold) public onlyMultisig {
        if (newThreshold == 0) {
            revert InvalidNumberOfConfirmationsRequired();
        }
        if (newThreshold > owners.length) {
            revert InvalidNumberOfConfirmationsRequired();
        }
        threshold = newThreshold;
    }

    /// @notice Adds a new owner
    /// @param newOwner Address to add as owner
    /// @dev Must be called through multisig, cannot be zero or existing owner
    function addOwner(address newOwner) public onlyMultisig {
        if (newOwner == address(0)) {
            revert ZeroAddressOwner();
        }

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == newOwner) {
                revert OwnerAlreadyExists();
            }
        }

        owners.push(newOwner);
    }

    /// @notice Removes an existing owner
    /// @param ownerToRemove Address to remove from owners
    /// @dev Must be called through multisig, cannot make threshold impossible
    function removeOwner(address ownerToRemove) public onlyMultisig {
        if (owners.length <= threshold) {
            revert CannotRemoveOwner();
        }

        bool found = false;
        uint256 indexToRemove;

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == ownerToRemove) {
                indexToRemove = i;
                found = true;
                break;
            }
        }

        if (!found) {
            revert OwnerDoesNotExist();
        }

        owners[indexToRemove] = owners[owners.length - 1];
        owners.pop();
    }

    /* -------------------- */
    /* 11. VIEW FUNCTIONS   */
    /* -------------------- */

    /// @notice Retrieves a transaction's details
    /// @param index The index of the transaction
    /// @return The complete transaction struct
    /// @dev Returns all transaction fields including votes and execution status
    function transactionByIndex(uint256 index) public view returns (Transaction memory) {
        return transactions[index];
    }
}
