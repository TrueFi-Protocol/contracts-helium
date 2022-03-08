// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {InitializableManageable} from "../access/InitializableManageable.sol";
import {IValuationStrategy} from "../interfaces/IValuationStrategy.sol";
import {IDebtInstrument} from "../interfaces/IDebtInstrument.sol";
import {IBasePortfolio} from "../interfaces/IBasePortfolio.sol";

contract MultiInstrumentValuationStrategy is InitializableManageable, IValuationStrategy {
    IDebtInstrument[] public instruments;
    mapping(IDebtInstrument => IValuationStrategy) public strategies;

    modifier onlyPortfolio(IBasePortfolio portfolio) {
        require(msg.sender == address(portfolio), "MultiInstrumentValuationStrategy: Can only be called by portfolio");
        _;
    }

    constructor() InitializableManageable(msg.sender) {}

    function initialize() external initializer {
        InitializableManageable.initialize(msg.sender);
    }

    function addStrategy(IDebtInstrument instrument, IValuationStrategy strategy) external onlyManager {
        strategies[instrument] = strategy;
        for (uint256 i; i < instruments.length; i++) {
            if (instruments[i] == instrument) {
                return;
            }
        }
        instruments.push(instrument);
    }

    function onInstrumentFunded(
        IBasePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external onlyPortfolio(portfolio) {
        strategies[instrument].onInstrumentFunded(portfolio, instrument, instrumentId);
    }

    function onInstrumentUpdated(
        IBasePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external onlyPortfolio(portfolio) {
        strategies[instrument].onInstrumentUpdated(portfolio, instrument, instrumentId);
    }

    function getSupportedInstruments() external view returns (IDebtInstrument[] memory) {
        return instruments;
    }

    function liquidValue(IBasePortfolio portfolio) public view returns (uint256) {
        return portfolio.underlyingToken().balanceOf(address(portfolio));
    }

    function calculateValue(IBasePortfolio portfolio) external view returns (uint256) {
        uint256 value = 0;
        for (uint256 i; i < instruments.length; i++) {
            value += strategies[instruments[i]].calculateValue(portfolio);
        }
        return value + liquidValue(portfolio);
    }
}
