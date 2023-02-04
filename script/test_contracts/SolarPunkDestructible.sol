// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {SolarPunk} from "src/SolarPunk.sol";
import {Destructible} from "script/utils/Destructible.sol";

contract SolarPunkDestructible is SolarPunk, Destructible {
    constructor() SolarPunk(msg.sender) {}
}
