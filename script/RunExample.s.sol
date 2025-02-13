// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Multisig} from "../src/Multisig.sol";
import {Counter} from "../src/Counter.sol";
import {Deploy} from "./Deploy.s.sol";

contract RunExample is Script {
    Multisig public multisig;
    Counter public counter;

    function setUp() public {}

    function run() public {
        // 1. Define owners addresses (Anvil accounts 2 to 4)
        string[] memory ownersAddresses = new string[](3);
        ownersAddresses[0] = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
        ownersAddresses[1] = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC";
        ownersAddresses[2] = "0x90F79bf6EB2c4f870365E785982E1f101E93b906";

        // 2. Define non-owner private key (Anvil account 1)
        uint256 nonOwnerPrivateKey = uint256(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);

        // 3. Define owners private keys (Anvil accounts 2 to 4)
        uint256[] memory ownersPrivateKeys = new uint256[](3);
        ownersPrivateKeys[0] = uint256(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);
        ownersPrivateKeys[1] = uint256(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a);
        ownersPrivateKeys[2] = uint256(0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6);

        // 4. Set env vars
        vm.setEnv("THRESHOLD", "2");

        // 5. Set owners addresses
        string memory ownersAddressesString = "";
        for (uint256 i = 0; i < ownersAddresses.length; i++) {
            ownersAddressesString = string(abi.encodePacked(ownersAddressesString, ownersAddresses[i]));
            // prevent last comma
            if (i < ownersAddresses.length - 1) {
                ownersAddressesString = string(abi.encodePacked(ownersAddressesString, ","));
            }
        }
        vm.setEnv("OWNERS", ownersAddressesString);

        // 6. Deploy Multisig
        vm.envOr("PRIVATE_KEY", nonOwnerPrivateKey);
        Deploy deployer = new Deploy();
        deployer.run();
        multisig = Multisig(address(deployer.multisig()));

        // 7. Deploy Counter
        vm.startBroadcast(nonOwnerPrivateKey);
        counter = new Counter(address(multisig));
        vm.stopBroadcast();

        // 8. Propose a transaction to increment the counter
        vm.startBroadcast(nonOwnerPrivateKey);
        multisig.proposeTransaction(address(counter), abi.encodeWithSelector(Counter.increment.selector));
        vm.stopBroadcast();

        // 9. Vote on the transaction
        vm.startBroadcast(ownersPrivateKeys[0]);
        multisig.voteForTransaction(0);
        vm.stopBroadcast();
        vm.startBroadcast(ownersPrivateKeys[1]);
        multisig.voteForTransaction(0);
        vm.stopBroadcast();
        // vm.startBroadcast(ownersPrivateKeys[2]);
        // multisig.voteForTransaction(0);
        // vm.stopBroadcast();

        // 10. Execute the transaction
        vm.startBroadcast(nonOwnerPrivateKey);
        multisig.executeTransaction(0);
        vm.stopBroadcast();

        // 11. Check the counter
        console.log("Counter value:", counter.number());
    }
}
