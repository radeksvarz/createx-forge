// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CreateXScript} from "./CreateXScript.sol";

// Example contract
import {Counter} from "../src/Counter.sol";

contract DeployExampleCounter is Script, CreateXScript {
    function setUp() public {
        //
        // Check there is a CreateX factory deployed
        // If not, etch it when running within a Forge testing environment (chainID = 31337)
        //
        // This sets `CreateX` for the scripting usage with functions:
        //      https://github.com/pcaversaccio/createx#available-versatile-functions
        //
        // WARNING - etching is not supported towards local explicit Anvil execution with default chainID
        //      This leads to a strange behaviour towards Anvil when Anvil does not have CreateX predeployed
        //      (seamingly correct transactions in the forge simulation even when broadcasted).
        //      Start Anvil with a different chainID, e.g. `anvil --chain-id 1982` to simulate a correct behaviour
        //      of missing CreateX.
        //
        // Behaviour towards external RPCs - this works as expected, i.e. continues if CreateX is deployed
        // and stops when not. (Tested with Tenderly devnets and BuildBear private testnets)
        //
        setUpCreateXFactory();
    }

    function run() public {
        vm.startBroadcast();

        // Note: Default Foundry address for msg.sender: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38.
        address deployer = msg.sender;

        console2.log("Deployer:", deployer);

        //
        // Example of the address determination
        //

        // Set salt with frontrunning protection, i.e. first 20 bytes = deployer;
        // 0 byte to switch off cross-chain redeploy protection; 11 bytes salt
        // Details: https://github.com/pcaversaccio/createx#permissioned-deploy-protection-and-cross-chain-redeploy-protection
        bytes32 salt = bytes32(abi.encodePacked(deployer, hex"00", bytes11(uint88(1982))));

        // Calculate the predetermined address of the Counter contract deployment
        address computedAddress = computeCreate3Address(salt, deployer);

        console2.log("Computed contract address:", computedAddress);

        //
        // Example of the CREATE3 deployment
        //

        // Demo to show handling of constructor arguments
        uint256 arg1 = 42;

        address deployedAddress = create3(salt, abi.encodePacked(type(Counter).creationCode, arg1));

        console2.log("Deployed contract address:", deployedAddress);

        // Check to make sure contract is on the expected address
        require(computedAddress == deployedAddress, "Computed and deployed address do not match!");

        //
        // Work with the example contract
        //
        Counter counter = Counter(deployedAddress);

        require(counter.number() == arg1);
        counter.increment();
        require(counter.number() == arg1 + 1);

        vm.stopBroadcast();
    }
}
