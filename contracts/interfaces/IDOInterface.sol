// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IBEP20.sol";

interface IDOInterface {
    function beneficiary() external view returns (address);
    function collateralRate() external view returns (uint);
    function borrowRate() external view returns (uint);
    function done() external view returns (bool);
    function asset() external view returns (IBEP20);
    function baseAsset() external view returns (IBEP20);
    function totalJoined() external view returns (uint);
    function totalAdded() external view returns (uint);
    function borrowAmounts(address account) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function balanceOfAdd(address account) external view returns (uint);
    function offeringAmount() external view returns (uint);
    function leftOfferingAmount() external view returns (uint);
    function totalSupply() external view returns (uint);
    function totalSupplyAdd() external view returns (uint);

    function fundingStartBlock() external view returns (uint);
    function fundingEndBlock() external view returns (uint);
    function addEndBlock() external view returns (uint);
    function totalEndBlock() external view returns (uint);
    function minInvestingAmount() external view returns (uint);
    function maxInvestingAmount() external view returns (uint);
    function totalInvestingAmount() external view returns (uint);
    function refundInvestingAmount() external view returns (uint);

    function setParameters(
        uint _fundingStartBlock,
        uint _fundingEndBlock,
        uint _addEndBlock,
        uint _totalEndBlock,
        uint _minInvestingAmount,
        uint _maxInvestingAmount,
        uint _refundInvestingAmount
    ) external;

    function lock() external;
    function join(address account, uint amount) external;
    function refund(address account) external returns (uint);
    function exit(address account) external returns (uint);
    function borrow(address account, uint shares) external returns (uint);
    function repay(address account, uint amount) external returns (uint);
    function add(address account, uint amount) external;
    function remove(address account) external returns (uint, uint);

    function reward() external returns (uint);
}