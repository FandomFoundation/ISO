// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IBEP20.sol";
import "./library/SafeMath.sol";
import "./library/SafeBEP20.sol";
import "./interfaces/ISOInterface.sol";

contract IDO {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    ISOInterface public iso;

    mapping (address => uint) public borrowAmounts;
    uint public totalAdded;
    uint public totalJoined;

    uint public totalSupply;
    mapping (address => uint) public balanceOf;

    uint public totalSupplyAdd;
    mapping (address => uint) public balanceOfAdd;

    IBEP20 public asset;
    IBEP20 public baseAsset;
    address public beneficiary;

    uint public collateralRate;
    uint public borrowRate;

    uint public offeringAmount;
    uint public leftOfferingAmount;

    uint public fundingStartBlock;
    uint public fundingEndBlock;
    uint public addEndBlock;
    uint public totalEndBlock;
    uint public minInvestingAmount;
    uint public maxInvestingAmount;
    uint public totalInvestingAmount;
    uint public refundInvestingAmount;

    bool public done;

    constructor(
        address _iso,
        address _asset,
        address _baseAsset,
        address _beneficiary,
        uint _collateralRate,
        uint _borrowRate,
        uint _offeringAmount,
        uint _totalInvestingAmount
    ) public {
        iso = ISOInterface(_iso);
        asset = IBEP20(_asset);
        baseAsset = IBEP20(_baseAsset);
        beneficiary = _beneficiary;
        collateralRate = _collateralRate;
        borrowRate = _borrowRate;
        offeringAmount = _offeringAmount;
        leftOfferingAmount = offeringAmount;
        totalInvestingAmount = _totalInvestingAmount;
    }

    function setParameters(
        uint _fundingStartBlock,
        uint _fundingEndBlock,
        uint _addEndBlock,
        uint _totalEndBlock,
        uint _minInvestingAmount,
        uint _maxInvestingAmount,
        uint _refundInvestingAmount
    ) public {
        checkController();

        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
        addEndBlock = _addEndBlock;
        totalEndBlock = _totalEndBlock;
        minInvestingAmount = _minInvestingAmount;
        maxInvestingAmount = _maxInvestingAmount;
        refundInvestingAmount = _refundInvestingAmount;
    }

    function lock() public {
        checkController();

        asset.safeTransferFrom(msg.sender, address(this), offeringAmount);
    }

    function join(address account, uint amount) public {
        checkController();

        baseAsset.safeTransferFrom(msg.sender, address(this), amount);

        balanceOf[account] = amount;
        totalSupply = totalSupply.add(amount);

        totalJoined = totalSupply;
    }

    function refund(address account) public returns (uint) {
        checkController();

        uint amount = balanceOf[account];
        totalSupply = totalSupply.sub(amount);
        totalJoined = totalSupply;
        balanceOf[account] = 0;

        baseAsset.safeTransfer(msg.sender, amount);
        if(!done) {
            done = true;
            asset.safeTransfer(beneficiary, offeringAmount);
        }
        return amount;
    }

    function exit(address account) public returns (uint) {
        checkController();

        uint shares = balanceOf[account];

        uint amount = shares
            .mul(leftOfferingAmount)
            .div(totalSupply);

        totalSupply = totalSupply.sub(shares);
        balanceOf[account] = 0;

        leftOfferingAmount = leftOfferingAmount.sub(amount);
        asset.safeTransfer(msg.sender, amount);

        return amount;
    }

    function borrow(address account, uint shares) public returns (uint) {
        checkController();

        balanceOf[account] = balanceOf[account].sub(shares);
        balanceOf[address(this)] = balanceOf[address(this)].add(shares);

        uint amount = shares
            .mul(collateralRate)
            .div(1e18);

        borrowAmounts[account] = borrowAmounts[account].add(amount);
        totalAdded = totalAdded.sub(amount);

        baseAsset.safeTransfer(msg.sender, amount);

        return amount;
    }

    function repay(address account, uint amount) public returns (uint) {
        checkController();

        baseAsset.safeTransferFrom(msg.sender, address(this), amount);
        borrowAmounts[account] = borrowAmounts[account].sub(amount);

        uint shares = amount
            .mul(1e18)
            .div(collateralRate)
            .mul(borrowRate)
            .div(1e18);

        balanceOf[address(this)] = balanceOf[address(this)].sub(shares);
        balanceOf[account] = balanceOf[account].add(shares);

        totalAdded = totalAdded.add(amount);

        return shares;
    }

    function add(address account, uint amount) public {
        checkController();

        baseAsset.safeTransferFrom(msg.sender, address(this), amount);

        balanceOfAdd[account] = balanceOfAdd[account].add(amount);
        totalSupplyAdd = totalSupplyAdd.add(amount);

        totalAdded = totalSupplyAdd;
    }

    function remove(address account) public returns (uint, uint) {
        checkController();

        uint addShares = balanceOfAdd[account];

        uint baseAmount = addShares
            .mul(totalAdded)
            .div(totalSupplyAdd);

        uint shares = addShares
            .mul(balanceOf[address(this)])
            .div(totalSupplyAdd);

        balanceOf[address(this)] = balanceOf[address(this)].sub(shares);
        balanceOf[account] = balanceOf[account].add(shares);

        totalSupplyAdd = totalSupplyAdd.sub(addShares);
        balanceOfAdd[account] = 0;

        totalAdded = totalAdded.sub(baseAmount);
        baseAsset.safeTransfer(msg.sender, baseAmount);

        return (baseAmount, shares);
    }

    function reward() public returns (uint) {
        checkController();

        done = true;
        baseAsset.safeTransfer(beneficiary, totalJoined);
        return totalJoined;
    }

    function checkController() internal view {
        require(msg.sender == iso.controller(), "!controller");
    }
}