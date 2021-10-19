// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./library/SafeMath.sol";
import "./library/SafeBEP20.sol";
import "./interfaces/ISOInterface.sol";
import "./interfaces/ControllerInterface.sol";
import "./interfaces/IDOInterface.sol";
import "./interfaces/LockInterface.sol";

contract Viewer {
    ISOInterface public iso;

    constructor(
        address _iso
    ) public {
        iso = ISOInterface(_iso);
    }

    function getAccountInfo(uint idx, address account) public view returns (uint, uint, uint) {
        IDOInterface ido = IDOInterface(ControllerInterface(iso.controller()).IDOs(idx));

        return (
            ido.balanceOf(account),
            ido.balanceOfAdd(account),
            ido.borrowAmounts(account));
    }

    function getIDOInfo(uint idx) public view returns (
        address,
        address,
        address,
        uint,
        uint,
        uint,
        uint
    ) {
        IDOInterface ido = IDOInterface(ControllerInterface(iso.controller()).IDOs(idx));

        return (
        address(ido.asset()),
        address(ido.baseAsset()),
        ido.beneficiary(),
        ido.collateralRate(),
        ido.borrowRate(),
        ido.offeringAmount(),
        ido.totalInvestingAmount());
    }

    function getIDOParameters(uint idx) public view returns (
        uint,
        uint,
        uint,
        uint,
        uint,
        uint,
        uint,
        uint,
        uint,
        uint,
        uint,
        uint
    ) {
        IDOInterface ido = IDOInterface(ControllerInterface(iso.controller()).IDOs(idx));

        return (
            ido.fundingStartBlock(),
            ido.fundingEndBlock(),
            ido.addEndBlock(),
            ido.totalEndBlock(),
            ido.minInvestingAmount(),
            ido.maxInvestingAmount(),
            ido.refundInvestingAmount(),
            ido.leftOfferingAmount(),
            ido.totalAdded(),
            ido.totalJoined(),
            ido.totalSupply(),
            ido.totalSupplyAdd());
    }
}