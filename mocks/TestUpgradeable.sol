// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Upgradeable} from "../access/Upgradeable.sol";

contract TestUpgradeable is Upgradeable {
    function initialize() external initializer {
        __Upgradeable_init(msg.sender);
    }
}
