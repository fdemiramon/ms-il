// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Counter
/// @notice A simple counter that can only be incremented by its owner
contract Counter {
    uint256 public number;
    address public owner;

    error NotOwner();

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function increment() external onlyOwner {
        number++;
    }

    function getNumber() external view returns (uint256) {
        return number;
    }
}
