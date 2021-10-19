// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IDO.sol";

contract Factory {
    constructor () public {}

    function newIDO(
        address _iso,
        address _asset,
        address _baseAsset,
        address _beneficiary,
        uint _collateralRate,
        uint _borrowRate,
        uint _offeringAmount,
        uint _totalInvestingAmount
    ) public returns (address) {
        return address(new IDO(
            _iso,
            _asset,
            _baseAsset,
            _beneficiary,
            _collateralRate,
            _borrowRate,
            _offeringAmount,
            _totalInvestingAmount));
    }
}