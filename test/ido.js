const { time, expectRevert } = require('@openzeppelin/test-helpers');

const Controller = artifacts.require('Controller');
const Factory = artifacts.require('Factory');
const ISO = artifacts.require('ISO');
const MockBEP20 = artifacts.require('MockBEP20');
const Lock = artifacts.require('Lock');

contract('IDO test', ([alice, bob, carol, dev]) => {

    before(async () => {

        this.iso = await ISO.new(dev, {from: dev});

        this.factory = await Factory.new({from: dev});
        await this.iso.setFactory(this.factory.address, {from: dev});

        this.reward = await MockBEP20.new("test", "test", "0", {from: dev});

        this.base = await MockBEP20.new("testbase", "testbase", "0", {from: dev});

        await this.base.mint(alice, "1000000", {from: bob});
        await this.base.mint(bob, "1000000", {from: bob});
        await this.base.mint(carol, "1000000", {from: bob});

    });

    beforeEach(async () => {
        this.lock = await Lock.new(this.iso.address, {from: dev});
        await this.iso.setLock(this.lock.address, {from: dev});

        this.controller = await Controller.new(this.iso.address, {from: dev});
        await this.iso.setController(this.controller.address, {from: dev});

        await this.base.approve(this.controller.address, "1000000", {from: alice});
        await this.base.approve(this.controller.address, "1000000", {from: bob});
        await this.base.approve(this.controller.address, "1000000", {from: carol});

        await this.lock.setLockUpAsset(this.base.address, {from: dev});
        await this.lock.setMinLockUpPeriod("1", {from: dev});

        await this.controller.addBaseAsset(this.base.address, {from: dev});
    });


    it('should work properly', async () => {

        await this.reward.mint(dev, "10000", {from: dev});
        await this.reward.approve(this.controller.address, "10000", {from: dev});
        let res = await this.controller.addIDO(
            this.reward.address,
            this.base.address,
            dev,
            "500000000000000000",
            "100000000000000000",
            "10000",
            "10000",
            {from: dev});
        console.log(res.receipt.gasUsed);
        res = await this.controller.setParameters("0", "100", "130", "160", "190", "2", "1000", "0", {from: dev});
        console.log(res.receipt.gasUsed);


        let arr = [alice, bob, carol];

        /*
        for (let i = 0; i < 11; i++) {
            arr.push(alice);
        }
        */


        res = await this.controller.addWhitelists("0", arr, {from: dev});

        console.log(res.receipt.gasUsed);

        await this.lock.lock({from: alice});
        await this.lock.lock({from: bob});
        await this.lock.lock({from: carol});

        await time.advanceBlockTo("100");

        res = await this.controller.join("0", "99", {from: bob});
        console.log(res.receipt.gasUsed);

        await expectRevert(
            this.controller.join("0", "99", {from: bob}),
            "joined"
        )

        res = await this.controller.join("0", "77", {from: alice});
        console.log(res.receipt.gasUsed);
        res = await this.controller.join("0", "3", {from: carol});
        console.log(res.receipt.gasUsed);

        await time.advanceBlockTo("130");

        res = await this.controller.add("0", "999", {from: bob});
        console.log(res.receipt.gasUsed);
        res = await this.controller.add("0", "999", {from: bob});
        console.log(res.receipt.gasUsed);



        res = await this.controller.add("0", "7", {from: alice});
        console.log(res.receipt.gasUsed);
        res = await this.controller.add("0", "77", {from: alice});
        console.log(res.receipt.gasUsed);


        await time.advanceBlockTo("160");

        res = await this.controller.borrow("0", "10", {from: alice});
        console.log(res.receipt.gasUsed);
        res = await this.controller.repay("0", "7", {from: alice});
        console.log(res.receipt.gasUsed);
        res = await this.controller.repay("0", "100", {from: alice});
        console.log(res.receipt.gasUsed);

        res = await this.controller.borrow("0", "99", {from: bob});
        console.log(res.receipt.gasUsed);
        res = await this.controller.borrow("0", "3", {from: carol});
        console.log(res.receipt.gasUsed);
        res = await this.controller.repay("0", "1", {from: bob});
        console.log(res.receipt.gasUsed);
        res = await this.controller.repay("0", "100", {from: bob});
        console.log(res.receipt.gasUsed);
        res = await this.controller.borrow("0", "9", {from: bob});
        console.log(res.receipt.gasUsed);

        res = await this.controller.repay("0", "100", {from: carol});
        console.log(res.receipt.gasUsed);


        await time.advanceBlockTo("190");

        res = await this.controller.exit("0", {from: carol});
        console.log(res.receipt.gasUsed);
        res = await this.controller.remove("0", {from: alice});
        console.log(res.receipt.gasUsed);
        res = await this.controller.exit("0", {from: alice});
        console.log(res.receipt.gasUsed);
        res = await this.controller.remove("0", {from: bob});
        console.log(res.receipt.gasUsed);
        res = await this.controller.exit("0", {from: bob});
        console.log(res.receipt.gasUsed);
        res = await this.controller.reward("0", {from: bob});
        console.log(res.receipt.gasUsed);


    });
});