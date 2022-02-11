// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDebtInstrument} from "./IDebtInstrument.sol";

enum BulletLoanStatus {
    Created,
    Started,
    FullyRepaid,
    Defaulted,
    Resolved
}

interface IBulletLoans is IDebtInstrument {
    struct LoanMetadata {
        IERC20 underlyingToken;
        BulletLoanStatus status;
        uint64 duration;
        uint64 repaymentDate;
        address recipient;
        uint256 principal;
        uint256 totalDebt;
        uint256 amountRepaid;
    }

    function loans(uint256 id)
        external
        view
        returns (
            IERC20,
            BulletLoanStatus,
            uint64,
            uint64,
            address,
            uint256,
            uint256,
            uint256
        );

    function createLoan(
        IERC20 _underlyingToken,
        uint256 principal,
        uint256 totalDebt,
        uint64 duration,
        address recipient
    ) external returns (uint256);

    function startLoan(uint256 instrumentId) external;

    function markLoanAsDefaulted(uint256 instrumentId) external;

    function markLoanAsResolved(uint256 instrumentId) external;
}
