// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDebtInstrument} from "./IDebtInstrument.sol";

enum PeriodicLoanStatus {
    Created,
    Accepted,
    Started,
    Repaid,
    Canceled,
    Defaulted
}

interface IPeriodicLoans is IDebtInstrument {
    struct LoanMetadata {
        uint256 principal;
        uint256 totalDebt;
        uint256 periodPayment;
        PeriodicLoanStatus status;
        uint16 periodCount;
        uint32 periodDuration;
        uint40 currentPeriodEndDate;
        address recipient;
        bool canBeRepaidAfterDefault;
        uint16 periodsRepaid;
        uint32 gracePeriod;
        uint40 endDate;
        IERC20 underlyingToken;
    }

    function loans(uint256 id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            PeriodicLoanStatus,
            uint16,
            uint32,
            uint40,
            address,
            bool,
            uint16,
            uint32,
            uint40,
            IERC20
        );

    function issueLoan(
        IERC20 _underlyingToken,
        uint256 _principal,
        uint16 _periodCount,
        uint256 _periodPayment,
        uint32 _periodDuration,
        address _recipient,
        uint32 _gracePeriod,
        bool _canBeRepaidAfterDefault
    ) external returns (uint256);

    function updateInstrument(uint256 _instrumentId, uint32 _gracePeriod) external;

    function status(uint256 instrumentId) external view returns (PeriodicLoanStatus);
}
