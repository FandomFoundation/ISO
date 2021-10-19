const { time, expectRevert } = require('@openzeppelin/test-helpers');

const Controller = artifacts.require('Controller');
const Factory = artifacts.require('Factory');
const ISO = artifacts.require('ISO');
const MockBEP20 = artifacts.require('MockBEP20');
const Lock = artifacts.require('Lock');

contract('Controller test', ([alice, bob, carol, dev]) => {

    before(async () => {
        this.iso = await ISO.new(dev, {from: dev});

        this.factory = await Factory.new({from: dev});
        await this.iso.setFactory(this.factory.address, {from: dev});

        this.reward = await MockBEP20.new("test", "test", "0", {from: dev});

        this.base = await MockBEP20.new("testbase", "testbase", "0", {from: dev});
    });

    beforeEach(async () => {
        this.lock = await Lock.new(this.iso.address, {from: dev});
        await this.iso.setLock(this.lock.address, {from: dev});

        this.controller = await Controller.new(this.iso.address, {from: dev});
        await this.iso.setController(this.controller.address, {from: dev});
    });

    it('should add IDO properly', async () => {
        await expectRevert(
            this.controller.addIDO(
                this.reward.address,
                this.base.address,
                alice,
                "5000000000000000000",
                "1000000000000000000",
                "10000",
                "10000",
                {from: alice}),
            "!admin"
        );

        await expectRevert(
            this.controller.addIDO(
                this.reward.address,
                this.base.address,
                alice,
                "5000000000000000000",
                "1000000000000000000",
                "10000",
                "10000",
                {from: dev}),
            "!collateral"
        );

        await expectRevert(
            this.controller.addIDO(
                this.reward.address,
                this.base.address,
                alice,
                "500000000000000000",
                "1000000000000000000",
                "10000",
                "10000",
                {from: dev}),
            "!borrow"
        );

        await expectRevert(
            this.controller.addIDO(
                this.reward.address,
                this.base.address,
                alice,
                "500000000000000000",
                "100000000000000000",
                "10000",
                "10000",
                {from: dev}),
            "!baseAsset"
        );

        await this.controller.addBaseAsset(this.base.address, {from: dev});
        await this.reward.mint(alice, "10000", {from: dev});
        await this.reward.approve(this.controller.address, "10000", {from: alice});
        await this.controller.addIDO(
            this.reward.address,
            this.base.address,
            alice,
            "500000000000000000",
            "100000000000000000",
            "10000",
            "10000",
            {from: dev});
    });

    it('should set IDO parameters properly', async () => {
        await this.reward.mint(alice, "10000", {from: dev});
        await this.reward.approve(this.controller.address, "10000", {from: alice});
        await this.controller.addBaseAsset(this.base.address, {from: dev});
        await this.controller.addIDO(
            this.reward.address,
            this.base.address,
            alice,
            "500000000000000000",
            "100000000000000000",
            "10000",
            "10000",
            {from: dev});

        await expectRevert(
            this.controller.setParameters("1", "0", "0", "0", "0", "0", "0", "0", {from: dev}),
            "!IDO"
        );

        await expectRevert(
            this.controller.setParameters("0", "0", "0", "0", "0", "0", "0", "0", {from: dev}),
            "!beneficiary"
        );

        await expectRevert(
            this.controller.setParameters("0", "0", "0", "0", "0", "0", "0", "0", {from: alice}),
            "!period"
        );

        await expectRevert(
            this.controller.setParameters("0", "100", "110", "120", "130", "0", "0", "100000", {from: alice}),
            "amount"
        );

        await this.controller.setParameters("0", "100", "110", "120", "130", "0", "100", "100", {from: alice});

        await expectRevert(
            this.controller.setParameters("0", "100", "110", "120", "130", "0", "0", "100", {from: alice}),
            "set"
        );
    });

    it('should work properly', async () => {
        await this.reward.mint(alice, "10000", {from: dev});
        await this.reward.approve(this.controller.address, "10000", {from: alice});
        await this.controller.addBaseAsset(this.base.address, {from: dev});
        await this.controller.addIDO(
            this.reward.address,
            this.base.address,
            alice,
            "500000000000000000",
            "100000000000000000",
            "10000",
            "10000",
            {from: dev});

        await this.reward.mint(alice, "10000", {from: alice});
        await this.reward.approve(this.controller.address, "10000", {from: alice});
        await this.controller.setParameters("0", "100", "110", "120", "130", "2", "100", "0", {from: alice});

        await expectRevert(
            this.controller.join("1", "1", {from: bob}),
            "!IDO"
        );

        await expectRevert(
            this.controller.join("0", "1", {from: bob}),
            "!locked"
        );

        await this.lock.setLockUpAsset(this.base.address, {from: dev});
        await this.lock.setMinLockUpPeriod("1", {from: dev});
        await this.lock.lock({from: bob});
        await this.lock.lock({from: carol});

        await this.controller.addWhitelists("0", [bob], {from: alice});
        await expectRevert(
            this.controller.join("0", "1", {from: carol}),
            "!whitelisted"
        );

        await expectRevert(
            this.controller.join("0", "1", {from: bob}),
            "!period"
        );

        await time.advanceBlockTo("100");
        await expectRevert(
            this.controller.join("0", "1", {from: bob}),
            "!amount"
        );

        await expectRevert(
            this.controller.join("0", "101", {from: bob}),
            "!amount"
        );

        await this.base.mint(bob, "1000000", {from: bob});
        await this.base.approve(this.controller.address, "99", {from: bob});
        await this.controller.join("0", "99", {from: bob});

        await this.base.approve(this.controller.address, "99", {from: bob});
        await expectRevert(
            this.controller.join("0", "99", {from: bob}),
            "joined"
        );

        await expectRevert(
            this.controller.add("0", "50", {from: bob}),
            "!period"
        );

        await time.advanceBlockTo("110");

        await expectRevert(
            this.controller.join("0", "100", {from: bob}),
            "!period"
        );

        await this.controller.add("0", "99", {from: bob});

        await expectRevert(
            this.controller.borrow("0", "1", {from: bob}),
            "!period"
        );

        await expectRevert(
            this.controller.repay("0", "100", {from: bob}),
            "!period"
        );

        await time.advanceBlockTo("120");

        await expectRevert(
            this.controller.add("0", "100", {from: bob}),
            "!period"
        );

        await this.controller.borrow("0", "1", {from: bob});

        await this.controller.repay("0", "100", {from: bob});

        await expectRevert(
            this.controller.exit("0", {from: bob}),
            "!period"
        );

        await expectRevert(
            this.controller.remove("0", {from: bob}),
            "!period"
        );

        await expectRevert(
            this.controller.reward("0", {from: bob}),
            "!period"
        );

        await time.advanceBlockTo("130");

        await this.controller.remove("0", {from: bob});
        await this.controller.exit("0", {from: bob});
        await this.controller.reward("0", {from: bob});

        await expectRevert(
            this.controller.reward("0", {from: bob}),
            "rewarded"
        );


    });

    it('should refund properly', async () => {
        await this.reward.mint(alice, "10000", {from: dev});
        await this.reward.approve(this.controller.address, "10000", {from: alice});
        await this.controller.addBaseAsset(this.base.address, {from: dev});
        await this.controller.addIDO(
            this.reward.address,
            this.base.address,
            alice,
            "500000000000000000",
            "100000000000000000",
            "10000",
            "10000",
            {from: dev});

        await this.reward.mint(alice, "10000", {from: alice});
        await this.reward.approve(this.controller.address, "10000", {from: alice});
        await this.controller.setParameters("0", "200", "210", "220", "230", "2", "100", "100", {from: alice});

        await this.lock.setLockUpAsset(this.base.address, {from: dev});
        await this.lock.setMinLockUpPeriod("1", {from: dev});
        await this.lock.lock({from: bob});

        await this.controller.addWhitelists("0", [bob], {from: alice});
        await time.advanceBlockTo("200");

        await this.base.mint(bob, "1000000", {from: bob});
        await this.base.approve(this.controller.address, "99", {from: bob});
        await this.controller.join("0", "99", {from: bob});

        await time.advanceBlockTo("210");

        await expectRevert(
            this.controller.add("0", "99", {from: bob}),
            "min"
        );

        await expectRevert(
            this.controller.borrow("0", "1", {from: bob}),
            "min"
        );

        await expectRevert(
            this.controller.repay("0", "100", {from: bob}),
            "min"
        );

        await expectRevert(
            this.controller.exit("0", {from: bob}),
            "min"
        );

        await expectRevert(
            this.controller.remove("0", {from: bob}),
            "min"
        );

        await expectRevert(
            this.controller.reward("0", {from: bob}),
            "min"
        );

        await this.controller.refund("0", {from: bob});



    });

});