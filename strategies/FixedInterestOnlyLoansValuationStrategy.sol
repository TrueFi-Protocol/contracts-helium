// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IValuationStrategy} from "../interfaces/IValuationStrategy.sol";
import {IDebtInstrument} from "../interfaces/IDebtInstrument.sol";
import {IFixedInterestOnlyLoans, FixedInterestOnlyLoanStatus} from "../interfaces/IFixedInterestOnlyLoans.sol";
import {Upgradeable} from "../access/Upgradeable.sol";
import {IBasePortfolio} from "../interfaces/IBasePortfolio.sol";

contract FixedInterestOnlyLoansValuationStrategy is Upgradeable, IValuationStrategy {
    struct PortfolioDetails {
        uint256 value;
        mapping(uint256 => bool) isLoanActive;
    }

    address public parentStrategy;
    IFixedInterestOnlyLoans public fixedInterestOnlyLoansAddress;
    mapping(IBasePortfolio => PortfolioDetails) public portfolioDetails;

    event InstrumentFunded(IBasePortfolio indexed portfolio, IDebtInstrument indexed instrument, uint256 indexed instrumentId);

    modifier onlyPortfolioOrParentStrategy(IBasePortfolio portfolio) {
        require(
            msg.sender == address(portfolio) || msg.sender == parentStrategy,
            "FixedInterestOnlyLoansValuationStrategy: Only portfolio or parent strategy"
        );
        _;
    }

    function initialize(IFixedInterestOnlyLoans _fixedInterestOnlyLoansAddress, address _parentStrategy) external initializer {
        __Upgradeable_init(msg.sender);
        fixedInterestOnlyLoansAddress = _fixedInterestOnlyLoansAddress;
        parentStrategy = _parentStrategy;
    }

    function onInstrumentFunded(
        IBasePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external onlyPortfolioOrParentStrategy(portfolio) {
        require(instrument == fixedInterestOnlyLoansAddress, "FixedInterestOnlyLoansValuationStrategy: Unexpected instrument");

        PortfolioDetails storage _portfolioDetails = portfolioDetails[portfolio];
        _portfolioDetails.isLoanActive[instrumentId] = true;
        _portfolioDetails.value += instrument.principal(instrumentId);

        emit InstrumentFunded(portfolio, instrument, instrumentId);
    }

    function onInstrumentUpdated(
        IBasePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external onlyPortfolioOrParentStrategy(portfolio) {
        require(instrument == fixedInterestOnlyLoansAddress, "FixedInterestOnlyLoansValuationStrategy: Unexpected instrument");
        _tryToExcludeLoan(portfolio, instrument, instrumentId);
    }

    function _tryToExcludeLoan(
        IBasePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) private {
        PortfolioDetails storage _portfolioDetails = portfolioDetails[portfolio];
        bool isActive = _portfolioDetails.isLoanActive[instrumentId];
        if (!isActive) {
            return;
        }
        FixedInterestOnlyLoanStatus status = IFixedInterestOnlyLoans(address(instrument)).status(instrumentId);
        if (status != FixedInterestOnlyLoanStatus.Started) {
            _portfolioDetails.isLoanActive[instrumentId] = false;
            _portfolioDetails.value -= instrument.principal(instrumentId);
        }
    }

    function calculateValue(IBasePortfolio portfolio) external view returns (uint256) {
        return portfolioDetails[portfolio].value;
    }

    function isLoanActive(IBasePortfolio portfolio, uint256 instrumentId) external view returns (bool) {
        return portfolioDetails[portfolio].isLoanActive[instrumentId];
    }
}
