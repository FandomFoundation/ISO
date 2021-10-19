// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface FactoryInterface {
    function newIDO(
        address _iso,
        address _asset,
        address _baseAsset,
        address _beneficiary,
        uint _collateralRate,
        uint _borrowRate,
        uint _offeringAmount,
        uint _totalInvestingAmount
    ) external returns (address);
}