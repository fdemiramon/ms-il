// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/// @title MS-IL
/// @author John Doe
/// @notice The Multisig contract.
contract Multisig {
    /* -------------------- */
    /* 1. CONSTANTS         */
    /* -------------------- */
    bytes32 constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(uint256 chainId,address)");

    /* -------------------- */
    /* 2. IMMUTABLE         */
    /* -------------------- */
    bytes32 public immutable DOMAIN_SEPARATOR;

    /* -------------------- */
    /* 3. TRANSIENT STORAGE */
    /* -------------------- */
    // none

    /* -------------------- */
    /* 4. STORAGE           */
    /* -------------------- */

    /// @notice Lorem ipsum
    /// @dev Lorem ipsum
    address[] public owners;

    /// @notice Lorem ipsum
    /// @dev Lorem ipsum
    uint8 public threshold;

    /* -------------------- */
    /* 5. EVENTS            */
    /* -------------------- */
    // none

    /* -------------------- */
    /* 6. MODIFIERS         */
    /* -------------------- */
    // none

    /* -------------------- */
    /* 7. CONSTRUCTOR       */
    /* -------------------- */

    /// @param _owners Lorem Ip
    constructor(address[] memory _owners) {
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, block.chainid, address(this)));
    }

    /* -------------------- */
    /* 8. CONSTRUCTOR       */
    /* -------------------- */
}
