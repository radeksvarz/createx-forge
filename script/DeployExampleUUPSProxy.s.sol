// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CreateXScript} from "./CreateXScript.sol";

// Example contract
// UUPS proxy with ERC20 implementation
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {ERC1967Proxy} from "../src/ERC1967Proxy.sol";

/**
 * @title Example deterministic deployment script for UUPS proxy and corresponding implementation
 * @notice ERC20 implementation is deployed normally, UUPS using create3.
 */
contract DeployExampleUUPSProxy is Script, CreateXScript {
    function setUp() public withCreateX {
        //
        // `withCreateX` modifier checks there is a CreateX factory deployed
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
    }

    function run() public {
        vm.startBroadcast();

        // Note: Default Foundry address for msg.sender: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38.
        address deployer = msg.sender;

        console2.log("Deployer:", deployer);

        //
        // Implementation is deployed normally using CREATE, i.e. contract's address is depending on deployer's address
        // and its nonce. This results in different addresses on different chains if nonce is not managed.
        // However this disadvantage is mitigated by the proxy entrypoint.
        // Additionally, implementations are bigger contracts, therefore CREATE3 approach is very costly
        // due to passing initicode several times in calldata.
        //
        MockERC20 implementation = new MockERC20();

        console2.log("Implementation deployed address:", address(implementation));

        // Demo to show handling of initialization arguments
        string memory name = "My Token";
        string memory symbol = "MTKN";
        uint8 decimals = 9;

        // Prepare the initialization call for the proxy with corresponding arguments
        bytes memory implementationInitializeData =
            abi.encodeWithSignature("initialize(string,string,uint8)", name, symbol, decimals);

        //
        // Example of the UUPS proxy address determination
        //

        // Set salt with frontrunning protection, i.e. first 20 bytes = deployer;
        // 0 byte to switch off cross-chain redeploy protection; 11 bytes some salt
        // Details: https://github.com/pcaversaccio/createx#permissioned-deploy-protection-and-cross-chain-redeploy-protection
        bytes32 salt = bytes32(abi.encodePacked(deployer, hex"00", bytes11(uint88(1978))));

        // Calculate the predetermined address of the Counter contract deployment
        address computedAddress = computeCreate3Address(salt, deployer);

        console2.log("Proxy computed contract address:", computedAddress);

        //
        // Example of the CREATE3 deployment
        //
        address deployedAddress = create3(
            salt,
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, implementationInitializeData))
        );

        console2.log("Proxy deployed contract address:", deployedAddress);

        // Check to make sure contract is on the expected address
        require(computedAddress == deployedAddress, "Computed and deployed address do not match!");

        //
        // Work with the example contract
        //
        MockERC20 erc20 = MockERC20(deployedAddress);

        // You should see proxy-delegate calls in the trace:
        //
        // ├─ [814] ERC1967Proxy::decimals() [staticcall]
        // │   ├─ [424] MockERC20::decimals() [delegatecall]
        // │   │   └─ ← 9
        require(erc20.decimals() == decimals);

        erc20.approve(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045, 123456789);

        require(erc20.allowance(deployer, 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045) == 123456789);

        vm.stopBroadcast();
    }
}
