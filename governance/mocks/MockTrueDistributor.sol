// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITrueDistributor} from "../interfaces/ITrueDistributor.sol";

contract MockTrueDistributor is ITrueDistributor {
    bool public isDistributed;
    address public farm;
    IERC20 public trustToken;
    uint256 public nextDistribution;

    constructor(IERC20 _trustToken, address _farm) {
        trustToken = _trustToken;
        farm = _farm;
    }

    function mockNextDistribution(uint256 _nextDistribution) external {
        nextDistribution = _nextDistribution;
    }

    function distribute() external {
        isDistributed = true;
    }

    function empty() external {}
}
