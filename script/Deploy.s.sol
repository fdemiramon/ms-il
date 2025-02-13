// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Multisig} from "../src/Multisig.sol";

contract Deploy is Script {
    Multisig public multisig;

    function setUp() public {}

    function run() public {
        // Get deployment parameters from environment
        uint8 threshold = uint8(vm.envOr("THRESHOLD", uint256(1)));
        uint256 deployerKey =
            vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address[] memory ownersDefaultArray = new address[](1);
        ownersDefaultArray[0] = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        address[] memory ownersArray = vm.envOr("OWNERS", ",", ownersDefaultArray);

        address[] memory owners = new address[](ownersArray.length);
        for (uint256 i = 0; i < ownersArray.length; i++) {
            owners[i] = ownersArray[i];
        }

        // Start broadcasting
        vm.startBroadcast(deployerKey);

        // Deploy contract
        multisig = new Multisig(owners, threshold);

        vm.stopBroadcast();
    }
}
