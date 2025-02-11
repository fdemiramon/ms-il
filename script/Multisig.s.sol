// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Multisig} from "../src/Multisig.sol";

contract MultisigScript is Script {
    Multisig public multisig;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        //multisig = new Multisig([address(0)]);

        vm.stopBroadcast();
    }
}
