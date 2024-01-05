// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Script.sol";

contract Counter {
    uint256 public number;

    constructor(uint256 initialNumber) {
        number = initialNumber;
        console.log(
            "Note, msg.sender for the constructor of the deployed contract is the createx proxy contract:", msg.sender
        );
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
