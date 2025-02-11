// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Multisig} from "../src/Multisig.sol";

contract MultisigTest is Test {
    Multisig public multisig;

    function setUp() public {
        address[] memory owners = new address[](1);
        owners[0] = address(0);

        multisig = new Multisig(owners);
    }

    function test_Foo() public {
        
    }

    
}
