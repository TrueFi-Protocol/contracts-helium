// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../AutomatedLineOfCredit.sol";

contract ALOCHarness is AutomatedLineOfCredit {
    using SafeERC20 for IERC20;

    // Sanity assumptions for functions

    // Access to internal functions/storage

    function unincludedInterestHarness() public view returns (uint256) {
        return super.unincludedInterest();
    }

    function _valueHarness(uint256 debt) public view returns (uint256) {
        return super._value(debt);
    }

    function _utilizationHarness(uint256 debt) public view returns (uint256) {
        return super._utilization(debt);
    }

    function totalFeeHarness() public view returns (uint256) {
        return super.totalFee();
    }

    // Access to other contracts' functions

    function tokenTransferHarness(
        address from,
        address to,
        uint256 amount
    ) public {
        require(from != address(this));
        underlyingToken.safeTransferFrom(from, to, amount);
    }
}
