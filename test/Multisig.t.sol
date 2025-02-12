// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Test, console2} from "forge-std/Test.sol";
import {Multisig} from "../src/Multisig.sol";
import {Transaction} from "../src/structs/Transaction.sol";

contract MultisigTest is Test {
    event TransactionProposed(
        uint256 indexed transactionIndex, address indexed proposer, address indexed to, bytes data
    );

    event TransactionVoted(uint256 indexed transactionIndex, address indexed voter);

    Multisig public multisig;
    address[] public owners;

    // Test addresses
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        // Setup owners
        owners.push(alice);
        owners.push(bob);
        owners.push(charlie);

        // Deploy contract with threshold of 2
        multisig = new Multisig(owners, 2);
    }

    function test_Constructor() public view {
        // Check that owners are correctly set
        assertEq(multisig.owners(0), alice);
        assertEq(multisig.owners(1), bob);
        assertEq(multisig.owners(2), charlie);
    }

    function test_Constructor_RevertZeroAddress() public {
        // Create owners array with a zero address
        address[] memory badOwners = new address[](3);
        badOwners[0] = alice;
        badOwners[1] = address(0); // zero address
        badOwners[2] = charlie;

        // Expect revert with ZeroAddressOwner error
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressOwner()"));
        new Multisig(badOwners, 2);
    }

    function test_Constructor_RevertDuplicateOwner() public {
        // Create owners array with duplicate addresses
        address[] memory duplicateOwners = new address[](3);
        duplicateOwners[0] = alice;
        duplicateOwners[1] = bob;
        duplicateOwners[2] = bob; // duplicate address

        // Expect revert with DuplicateOwner error
        vm.expectRevert(abi.encodeWithSignature("DuplicateOwner(address)", bob));
        new Multisig(duplicateOwners, 2);
    }

    function test_Constructor_RevertInvalidThreshold() public {
        // Try to create with threshold > owners
        vm.expectRevert(abi.encodeWithSignature("InvalidNumberOfConfirmationsRequired()"));
        new Multisig(owners, 4);

        // Try to create with threshold = 0
        vm.expectRevert(abi.encodeWithSignature("InvalidNumberOfConfirmationsRequired()"));
        new Multisig(owners, 0);
    }

    function test_ProposeTransaction() public {
        // Create sample transaction data
        address target = makeAddr("target");
        bytes memory data = abi.encodeWithSignature("someFunction(uint256)", 123);

        // Propose transaction as alice
        vm.prank(alice);
        multisig.proposeTransaction(target, data);

        // Get the transaction from storage as a Transaction struct
        Transaction memory transaction = multisig.transactionByIndex(0);

        // Verify transaction details
        assertEq(transaction.to, target);
        assertEq(transaction.data, data);
        assertFalse(transaction.isExecuted);
        assertEq(transaction.voters.length, 0);
    }

    function test_ProposeTransaction_EmitsEvent() public {
        address target = makeAddr("target");
        bytes memory data = abi.encodeWithSignature("someFunction(uint256)", 123);

        // 1. Setup emission checking
        vm.expectEmit(true, true, true, true, address(multisig));
        // 2. Emit the expected event
        emit TransactionProposed(0, alice, target, data);

        // 3. Perform the call that should emit the event
        vm.prank(alice);
        multisig.proposeTransaction(target, data);
    }

    function test_ProposeTransaction_EmptyCalldata() public {
        address target = makeAddr("target");
        bytes memory emptyData = "";

        // Propose transaction with empty calldata
        vm.prank(alice);
        multisig.proposeTransaction(target, emptyData);

        // Get the transaction from storage
        Transaction memory transaction = multisig.transactionByIndex(0);

        assertEq(transaction.to, target);
        assertEq(transaction.data, emptyData);
    }

    function test_ProposeTransaction_NonOwnerCanPropose() public {
        address nonOwner = makeAddr("nonOwner");
        address target = makeAddr("target");
        bytes memory data = abi.encodeWithSignature("someFunction()");

        // Ensure non-owner can propose
        vm.prank(nonOwner);
        multisig.proposeTransaction(target, data);

        // Verify transaction was stored
        Transaction memory transaction = multisig.transactionByIndex(0);
        assertEq(transaction.to, target);
    }

    function test_ProposeTransaction_MultipleProposals() public {
        address target = makeAddr("target");
        bytes memory data = abi.encodeWithSignature("someFunction()");

        // Propose multiple transactions
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(alice);
            multisig.proposeTransaction(target, data);
        }

        // Verify transaction count
        Transaction memory transaction = multisig.transactionByIndex(2);
        assertEq(transaction.to, target);
    }

    function test_VoteForTransaction() public {
        // Setup: Create and propose a transaction
        address target = makeAddr("target");
        bytes memory data = "";
        vm.prank(alice);
        multisig.proposeTransaction(target, data);

        // Vote for transaction as bob
        vm.prank(bob);
        multisig.voteForTransaction(0);

        // Verify vote was recorded
        Transaction memory transaction = multisig.transactionByIndex(0);
        assertEq(transaction.voters.length, 1);
        assertEq(transaction.voters[0], bob);
    }

    function test_VoteForTransaction_RevertIfAlreadyVoted() public {
        // Setup: Create and propose a transaction
        address target = makeAddr("target");
        bytes memory data = "";
        vm.prank(alice);
        multisig.proposeTransaction(target, data);

        // First vote should succeed
        vm.prank(bob);
        multisig.voteForTransaction(0);

        // Second vote should fail
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSignature("AlreadyVoted()"));
        multisig.voteForTransaction(0);
    }

    function test_VoteForTransaction_RevertIfNotOwner() public {
        // Setup: Create and propose a transaction
        address target = makeAddr("target");
        bytes memory data = "";
        vm.prank(alice);
        multisig.proposeTransaction(target, data);

        // Try to vote as non-owner
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("NotAnOwner()"));
        multisig.voteForTransaction(0);
    }

    function test_VoteForTransaction_RevertIfAlreadyExecuted() public {
        // Setup: Create and propose a transaction
        address target = makeAddr("target");
        bytes memory data = "";
        vm.prank(alice);
        multisig.proposeTransaction(target, data);

        // Get required votes
        vm.prank(bob);
        multisig.voteForTransaction(0);
        vm.prank(charlie);
        multisig.voteForTransaction(0);

        // Execute the transaction
        vm.prank(address(multisig));
        multisig.executeTransaction(0);

        // Try to vote on executed transaction
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSignature("TransactionAlreadyExecuted()"));
        multisig.voteForTransaction(0);
    }

    function test_VoteForTransaction_EmitsEvent() public {
        // Setup: Create and propose a transaction
        address target = makeAddr("target");
        bytes memory data = "";
        vm.prank(alice);
        multisig.proposeTransaction(target, data);

        // Expect the TransactionVoted event
        vm.expectEmit(true, true, false, false, address(multisig));
        emit TransactionVoted(0, bob);

        // Vote for transaction
        vm.prank(bob);
        multisig.voteForTransaction(0);
    }

    function test_VoteForTransaction_MultipleVoters() public {
        // Setup: Create and propose a transaction
        address target = makeAddr("target");
        bytes memory data = "";
        vm.prank(alice);
        multisig.proposeTransaction(target, data);

        // Vote with multiple owners
        vm.prank(bob);
        multisig.voteForTransaction(0);

        vm.prank(charlie);
        multisig.voteForTransaction(0);

        // Verify all votes were recorded
        Transaction memory transaction = multisig.transactionByIndex(0);
        assertEq(transaction.voters.length, 2);
        assertEq(transaction.voters[0], bob);
        assertEq(transaction.voters[1], charlie);
    }
}
