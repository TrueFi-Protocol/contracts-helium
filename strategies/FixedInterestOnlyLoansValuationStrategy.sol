// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IValuationStrategy} from "../interfaces/IValuationStrategy.sol";
import {IDebtInstrument} from "../interfaces/IDebtInstrument.sol";
import {IFixedInterestOnlyLoans, FixedInterestOnlyLoanStatus} from "../interfaces/IFixedInterestOnlyLoans.sol";
import {InitializableManageable} from "../access/InitializableManageable.sol";
import {IBasePortfolio} from "../interfaces/IBasePortfolio.sol";

contract FixedInterestOnlyLoansValuationStrategy is InitializableManageable, IValuationStrategy {
    address public parentStrategy;
    IFixedInterestOnlyLoans public fixedInterestOnlyLoansAddress;
    mapping(IBasePortfolio => uint256) public value;
    mapping(IBasePortfolio => mapping(uint256 => bool)) public activeLoans;

    event InstrumentFunded(IBasePortfolio portfolio, IDebtInstrument instrument, uint256 instrumentId);

    modifier onlyPortfolioOrParentStrategy(IBasePortfolio portfolio) {
        require(
            msg.sender == address(portfolio) || msg.sender == parentStrategy,
            "FixedInterestOnlyLoansValuationStrategy: Only portfolio or parent strategy"
        );
        _;
    }

    constructor() InitializableManageable(msg.sender) {}

    function initialize(IFixedInterestOnlyLoans _fixedInterestOnlyLoansAddress, address _parentStrategy) external initializer {
        InitializableManageable.initialize(msg.sender);
        fixedInterestOnlyLoansAddress = _fixedInterestOnlyLoansAddress;
        parentStrategy = _parentStrategy;
    }

    function onInstrumentFunded(
        IBasePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external onlyPortfolioOrParentStrategy(portfolio) {
        require(instrument == fixedInterestOnlyLoansAddress, "FixedInterestOnlyLoansValuationStrategy: Unexpected instrument");
        activeLoans[portfolio][instrumentId] = true;
        value[portfolio] += instrument.principal(instrumentId);
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
        bool isActive = activeLoans[portfolio][instrumentId];
        if (!isActive) {
            return;
        }
        FixedInterestOnlyLoanStatus status = IFixedInterestOnlyLoans(address(instrument)).status(instrumentId);
        if (status != FixedInterestOnlyLoanStatus.Started) {
            activeLoans[portfolio][instrumentId] = false;
            value[portfolio] -= instrument.principal(instrumentId);
        }
    }

    function calculateValue(IBasePortfolio portfolio) public view returns (uint256) {
        return value[portfolio];
    }
}
