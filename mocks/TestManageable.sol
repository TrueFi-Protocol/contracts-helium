// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Manageable} from "../access/Manageable.sol";

contract TestManageable is Manageable, Initializable {
    function initialize() external initializer {
        __Manageable_init(msg.sender);
    }
}
