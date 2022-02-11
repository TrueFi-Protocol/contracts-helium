// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDebtInstrument} from "./IDebtInstrument.sol";

interface IPeriodicLoans is IDebtInstrument {
    struct LoanMetadata {
        uint256 principal;
        uint256 totalDebt;
        uint256 periodPayment;
        uint32 periodCount;
        uint64 periodDuration;
        address recipient;
        IERC20 underlyingToken;
        uint64 endDate;
        uint32 gracePeriod;
    }
}
