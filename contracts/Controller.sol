// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./library/SafeMath.sol";
import "./library/SafeBEP20.sol";
import "./interfaces/ISOInterface.sol";
import "./interfaces/FactoryInterface.sol";
import "./interfaces/IDOInterface.sol";
import "./interfaces/LockInterface.sol";

contract Controller {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    ISOInterface public iso;

    uint private max32 = 2**32;

    mapping(address => uint) public isBaseAsset;
    mapping(address => address[]) public whitelists;
    mapping(address => mapping(address => bool)) public isWhitelisted;

    address[] public baseAssets;
    address[] public IDOs;

    event NewIDO(
        uint indexed idx,
        uint indexed baseAsset,
        address asset,
        address beneficiary,
        uint collateralRate,
        uint borrowRate,
        uint offeringAmount,
        uint totalInvestingAmount
    );
    event NewIDOParameters(
        uint indexed idx,
        uint fundingStartBlock,
        uint fundingEndBlock,
        uint addEndBlock,
        uint totalEndBlock,
        uint minInvestingAmount,
        uint maxInvestingAmount,
        uint refundInvestingAmount
    );

    event NewWhitelists(
        uint indexed idx,
        address[] newWhitelists
    );
    event Joined(
        uint indexed idx,
        address indexed account,
        uint amount
    );
    event Refunded(
        uint indexed idx,
        address indexed account,
        uint amount
    );
    event Maxed(
        uint indexed idx,
        address indexed account,
        uint amount
    );
    event Exited(
        uint indexed idx,
        address indexed account,
        uint amount,
        uint shares
    );
    event Borrowed(
        uint indexed idx,
        address indexed account,
        uint amount,
        uint shares
    );
    event Repaid(
        uint indexed idx,
        address indexed account,
        uint amount,
        uint shares
    );
    event Added(
        uint indexed idx,
        address indexed account,
        uint amount
    );
    event Removed(
        uint indexed idx,
        address indexed account,
        uint baseAmount,
        uint addShares,
        uint shares
    );
    event Rewarded(
        uint indexed idx,
        uint amount
    );
    event NewBaseAsset(address newBaseAsset);

    constructor(
        address _iso
    ) public {
        iso = ISOInterface(_iso);
    }

    function addBaseAsset(address newBaseAsset) public {
        checkAdmin();

        baseAssets.push(newBaseAsset);
        isBaseAsset[newBaseAsset] = baseAssets.length;

        emit NewBaseAsset(newBaseAsset);
    }

    function addIDO(
        address _asset,
        address _baseAsset,
        address _beneficiary,
        uint _collateralRate,
        uint _borrowRate,
        uint _offeringAmount,
        uint _totalInvestingAmount
    ) public {
        checkAdmin();
        require(_collateralRate < 1e18, "!collateral");
        require(_borrowRate < 1e18, "!borrow");
        require(isBaseAsset[_baseAsset] > 0, "!baseAsset");
        FactoryInterface factory = FactoryInterface(iso.factory());

        address newIDOAddress = factory.newIDO(
            address(iso),
            _asset,
            _baseAsset,
            _beneficiary,
            _collateralRate,
            _borrowRate,
            _offeringAmount,
            _totalInvestingAmount);

        IDOs.push(newIDOAddress);

        IDOInterface ido = IDOInterface(newIDOAddress);

        IBEP20 asset = ido.asset();
        asset.safeTransferFrom(_beneficiary, address(this), _offeringAmount);
        asset.safeApprove(newIDOAddress, _offeringAmount);
        ido.lock();


        emit NewIDO(
            IDOs.length - 1,
            isBaseAsset[_baseAsset] - 1,
            _asset,
            _beneficiary,
            _collateralRate,
            _borrowRate,
            _offeringAmount,
            _totalInvestingAmount);

    }

    function setParameters(
        uint idx,
        uint _fundingStartBlock,
        uint _fundingEndBlock,
        uint _addEndBlock,
        uint _totalEndBlock,
        uint _minInvestingAmount,
        uint _maxInvestingAmount,
        uint _refundInvestingAmount
    ) public {
        require(idx < IDOs.length, "!IDO");
        IDOInterface ido = IDOInterface(IDOs[idx]);
        require(msg.sender == ido.beneficiary(), "!beneficiary");
        require(block.number < _fundingStartBlock
            && _fundingStartBlock < _fundingEndBlock
            && _fundingEndBlock < _addEndBlock
            && _addEndBlock < _totalEndBlock
            && _totalEndBlock < max32, "!period");
        require(ido.fundingStartBlock() == 0, "set");
        require(_minInvestingAmount < _maxInvestingAmount
            && _refundInvestingAmount <= ido.totalInvestingAmount(), "amount");

        ido.setParameters(
            _fundingStartBlock,
            _fundingEndBlock,
            _addEndBlock,
            _totalEndBlock,
            _minInvestingAmount,
            _maxInvestingAmount,
            _refundInvestingAmount);

        emit NewIDOParameters(
            idx,
            _fundingStartBlock,
            _fundingEndBlock,
            _addEndBlock,
            _totalEndBlock,
            _minInvestingAmount,
            _maxInvestingAmount,
            _refundInvestingAmount);
    }

    function addWhitelists(uint idx, address[] memory newWhitelists) public {
        require(idx < IDOs.length, "!IDO");
        address ido = IDOs[idx];
        require(msg.sender == IDOInterface(ido).beneficiary(), "!beneficiary");

        checkPeriod(0, IDOInterface(ido).fundingStartBlock());

        for(uint i = 0; i < newWhitelists.length; i++) {
            whitelists[ido].push(newWhitelists[i]);
            isWhitelisted[ido][newWhitelists[i]] = true;
        }

        emit NewWhitelists(idx, newWhitelists);
    }

    function join(uint idx, uint amount) public {
        IDOInterface ido = checkIdx(idx);

        checkPeriod(ido.fundingStartBlock(), ido.fundingEndBlock());

        require(amount >= ido.minInvestingAmount() && amount < ido.maxInvestingAmount(), "!amount");

        uint shares = ido.balanceOf(msg.sender);
        require(shares == 0, "joined");

        uint totalJoined = ido.totalJoined();
        uint investingAmount = ido.totalInvestingAmount();

        if(totalJoined.add(amount) > investingAmount) {
            uint maxAmount = investingAmount.sub(totalJoined);
            emit Maxed(idx, msg.sender, amount.sub(maxAmount));
            amount = maxAmount;
        }
        if(amount == 0) return;

        IBEP20 baseAsset = ido.baseAsset();
        baseAsset.safeTransferFrom(msg.sender, address(this), amount);
        baseAsset.safeApprove(address(ido), amount);
        ido.join(msg.sender, amount);

        emit Joined(
            idx,
            msg.sender,
            amount
        );
    }

    function refund(uint idx) public {
        IDOInterface ido = checkIdx(idx);

        checkPeriod(ido.fundingEndBlock(), max32);
        require(ido.refundInvestingAmount() >= ido.totalJoined(), "!min");

        uint amount = ido.refund(msg.sender);
        ido.baseAsset().safeTransfer(msg.sender, amount);

        emit Refunded(
            idx,
            msg.sender,
            amount
        );
    }

    function exit(uint idx) public {
        IDOInterface ido = checkIdx(idx);

        checkMinJoined(ido.totalJoined(), ido.refundInvestingAmount());
        checkPeriod(ido.totalEndBlock(), max32);

        uint shares = ido.balanceOf(msg.sender);
        uint amount = ido.exit(msg.sender);
        ido.asset().safeTransfer(msg.sender, amount);

        emit Exited(
            idx,
            msg.sender,
            amount,
            shares
        );
    }

    function borrow(uint idx, uint shares) public {
        IDOInterface ido = checkIdx(idx);

        checkMinJoined(ido.totalJoined(), ido.refundInvestingAmount());
        checkPeriod(ido.addEndBlock(), ido.totalEndBlock());

        uint amount = ido.borrow(msg.sender, shares);
        ido.baseAsset().safeTransfer(msg.sender, amount);

        emit Borrowed(
            idx,
            msg.sender,
            amount,
            shares
        );
    }

    function repay(uint idx, uint amount) public {
        IDOInterface ido = checkIdx(idx);

        checkMinJoined(ido.totalJoined(), ido.refundInvestingAmount());
        checkPeriod(ido.addEndBlock(), ido.totalEndBlock());

        IBEP20 baseAsset = ido.baseAsset();
        uint maxAmount = ido.borrowAmounts(msg.sender);
        if(amount > maxAmount) amount = maxAmount;
        baseAsset.safeTransferFrom(msg.sender, address(this), amount);
        baseAsset.safeApprove(address(ido), amount);
        uint shares = ido.repay(msg.sender, amount);

        emit Repaid(
            idx,
            msg.sender,
            amount,
            shares
        );
    }

    function add(uint idx, uint amount) public {
        IDOInterface ido = checkIdx(idx);

        checkMinJoined(ido.totalJoined(), ido.refundInvestingAmount());
        checkPeriod(ido.fundingEndBlock(), ido.addEndBlock());

        uint totalAdded = ido.totalAdded();
        uint maxAddAmount = uint(ido.totalJoined())
            .mul(ido.collateralRate())
            .div(1e18);
        if(totalAdded.add(amount) > maxAddAmount) {
            amount = maxAddAmount.sub(totalAdded);
        }
        if(amount == 0) return;

        IBEP20 baseAsset = ido.baseAsset();
        baseAsset.safeTransferFrom(msg.sender, address(this), amount);
        baseAsset.safeApprove(address(ido), amount);
        ido.add(msg.sender, amount);

        emit Added(
            idx,
            msg.sender,
            amount
        );
    }

    function remove(uint idx) public {
        IDOInterface ido = checkIdx(idx);
        checkMinJoined(ido.totalJoined(), ido.refundInvestingAmount());
        checkPeriod(ido.totalEndBlock(), max32);

        uint addShares = ido.balanceOfAdd(msg.sender);
        (uint baseAmount, uint shares) = ido.remove(msg.sender);
        ido.baseAsset().safeTransfer(msg.sender, baseAmount);

        emit Removed(
            idx,
            msg.sender,
            baseAmount,
            addShares,
            shares
        );
    }

    function reward(uint idx) public {
        IDOInterface ido = checkIdx(idx);
        checkMinJoined(ido.totalJoined(), ido.refundInvestingAmount());
        checkPeriod(ido.totalEndBlock(), max32);
        require(!ido.done(), "rewarded");

        uint amount = ido.reward();

        emit Rewarded(
            idx,
            amount
        );
    }

    function checkIdx(uint idx) internal view returns (IDOInterface) {
        require(idx < IDOs.length, "!IDO");
        IDOInterface ido = IDOInterface(IDOs[idx]);
        require(LockInterface(iso.lock()).userLocked(msg.sender), "!locked");
        if(whitelists[address(ido)].length > 0) {
            require(isWhitelisted[address(ido)][msg.sender], "!whitelisted");
        }
        return ido;
    }

    function checkPeriod(uint fromBlock, uint toBlock) internal view {
        uint currentBlock = block.number;
        require(currentBlock >= fromBlock && currentBlock < toBlock, "!period");
    }

    function checkAdmin() internal view {
        require(msg.sender == iso.admin(), "!admin");
    }

    function checkMinJoined(uint currentJoined, uint minJoined) internal pure {
        require(currentJoined > minJoined, "min");
    }
}