// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {InitializableManageable} from "./access/InitializableManageable.sol";
import {IPeriodicLoans} from "./interfaces/IPeriodicLoans.sol";

contract PeriodicLoans is ERC721Upgradeable, InitializableManageable, IPeriodicLoans {
    LoanMetadata[] public loans;

    event LoanIssued(uint256 instrumentId);

    constructor() InitializableManageable(msg.sender) {}

    function initialize() external initializer {
        InitializableManageable.initialize(msg.sender);
        __ERC721_init("PeriodicLoans", "PL");
    }

    function principal(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].principal;
    }

    function underlyingToken(uint256 instrumentId) external view returns (IERC20) {
        return loans[instrumentId].underlyingToken;
    }

    function recipient(uint256 instrumentId) external view returns (address) {
        return loans[instrumentId].recipient;
    }

    function endDate(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].endDate;
    }

    function totalDebt(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].totalDebt;
    }

    function gracePeriod(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].gracePeriod;
    }

    function repay(uint256 instrumentId, uint256 amount) external {}

    function issueLoan(
        IERC20 _underlyingToken,
        uint256 _principal,
        uint32 _periodCount,
        uint256 _periodPayment,
        uint64 _periodDuration,
        address _recipient,
        uint32 _gracePeriod
    ) external returns (uint256) {
        require(_recipient != address(0), "PeriodicLoans: recipient cannot be the zero address");

        uint64 loanDuration = _periodCount * _periodDuration;
        require(loanDuration > 0, "PeriodicLoans: Loan duration must be greater than 0");

        uint256 _totalDebt = _periodPayment * _periodCount;
        require(_totalDebt >= _principal, "PeriodicLoans: Total debt must not be less than principal");

        uint256 id = loans.length;
        uint64 _endDate = uint64(block.timestamp) + loanDuration;
        loans.push(
            LoanMetadata(
                _principal,
                _totalDebt,
                _periodPayment,
                _periodCount,
                _periodDuration,
                _recipient,
                _underlyingToken,
                _endDate,
                _gracePeriod
            )
        );

        _safeMint(msg.sender, id);

        emit LoanIssued(id);
        return id;
    }
}
