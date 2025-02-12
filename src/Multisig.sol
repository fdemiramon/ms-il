// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./structs/Transaction.sol";
import "./interfaces/IMultisig.sol";

/// @title MS-IL
/// @author John Doe
/// @notice The Multisig contract.
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

    /// @notice Lorem ipsum
    /// @dev Lorem ipsum
    address[] public owners;

    /// @notice Lorem ipsum
    /// @dev Lorem ipsum
    uint8 public threshold;

    /// @notice Lorem ipsum
    /// @dev Lorem ipsum
    Transaction[] public transactions;

    /* -------------------- */
    /* 6. EVENTS            */
    /* -------------------- */
    // none

    /* -------------------- */
    /* 7. CUSTOM ERRORS     */
    /* -------------------- */

    error ZeroAddressOwner();
    error DuplicateOwner(address owner);
    error TransactionAlreadyExecuted();
    error NotAnOwner();
    error AlreadyVoted();
    error InvalidNumberOfConfirmationsRequired();
    error TransactionDoesNotExist();
    error NotEnoughVotes();
    error TransactionFailed();
    error OwnerAlreadyExists();
    error CannotRemoveOwner();
    error OwnerDoesNotExist();

    /* -------------------- */
    /* 8. MODIFIERS         */
    /* -------------------- */
    // create a modifier to check if the sender is the multisig contract
    modifier onlyMultisig() {
        require(msg.sender == address(this), "Only the multisig contract can call this function");
        _;
    }

    /* -------------------- */
    /* 9. CONSTRUCTOR       */
    /* -------------------- */

    /// @param _owners Lorem Ip
    /// @param _threshold Number of required confirmations
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

    function proposeTransaction(address to, bytes calldata data) public {
        Transaction memory transaction = Transaction({to: to, data: data, isExecuted: false, voters: new address[](0)});
        transactions.push(transaction);
        emit TransactionProposed(transactions.length - 1, msg.sender, to, data);
    }

    function voteForTransaction(uint256 transactionIndex) public {
        // check if the transaction is not already executed
        if (transactions[transactionIndex].isExecuted) {
            revert TransactionAlreadyExecuted();
        }

        // check if the sender is an owner
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

        // check if the voter has already voted, revert
        for (uint256 i = 0; i < transactions[transactionIndex].voters.length; i++) {
            if (transactions[transactionIndex].voters[i] == msg.sender) {
                revert AlreadyVoted();
            }
        }

        transactions[transactionIndex].voters.push(msg.sender);
        // emit an event
        emit TransactionVoted(transactionIndex, msg.sender);
    }

    function executeTransaction(uint256 transactionIndex) public onlyMultisig {
        // check if the transaction is not already executed
        if (transactions[transactionIndex].isExecuted) {
            revert TransactionAlreadyExecuted();
        }

        // check if the threshold is reached
        if (transactions[transactionIndex].voters.length < threshold) {
            revert NotEnoughVotes();
        }

        // execute the transaction
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

    function setThreshold(uint8 newThreshold) public onlyMultisig {
        if (newThreshold == 0) {
            revert InvalidNumberOfConfirmationsRequired();
        }
        if (newThreshold > owners.length) {
            revert InvalidNumberOfConfirmationsRequired();
        }
        threshold = newThreshold;
    }

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

        // Move the last element to the position we want to remove
        owners[indexToRemove] = owners[owners.length - 1];
        // Remove the last element
        owners.pop();
    }

    /* -------------------- */
    /* 11. VIEW FUNCTIONS   */
    /* -------------------- */

    /// @notice Get a transaction by its index
    /// @param index The index of the transaction
    /// @return The transaction at the given index
    function transactionByIndex(uint256 index) public view returns (Transaction memory) {
        return transactions[index];
    }
}
