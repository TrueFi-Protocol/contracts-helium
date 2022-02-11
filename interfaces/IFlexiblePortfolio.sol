// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IBasePortfolio} from "./IBasePortfolio.sol";

interface IFlexiblePortfolio is IBasePortfolio {
    event InstrumentAdded(uint256 instrumentId);
    event InstrumentFunded(uint256 instrumentId);

    function addInstrument(
        uint64 loanDuration,
        address borrower,
        uint256 principalAmount,
        uint256 repaymentAmount
    ) external returns (uint256);

    function fundInstrument(uint256 instrumentId) external;

    function addAndFundInstrument(
        uint64 loanDuration,
        address borrower,
        uint256 principalAmount,
        uint256 repaymentAmount
    ) external returns (uint256);
}
