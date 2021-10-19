const { time, expectRevert } = require('@openzeppelin/test-helpers');

const Factory = artifacts.require('Factory');
const ISO = artifacts.require('ISO');
const MockBEP20 = artifacts.require('MockBEP20');
const Lock = artifacts.require('Lock');

contract('Lock test', ([alice, bob, carol, dev]) => {

    before(async () => {
        this.iso = await ISO.new(dev, {from: dev});

        this.factory = await Factory.new({from: dev});
        await this.iso.setFactory(this.factory.address, {from: dev});

        this.reward = await MockBEP20.new("test", "test", "0", {from: dev});

        this.base = await MockBEP20.new("testbase", "testbase", "0", {from: dev});

        this.lock = await Lock.new(this.iso.address, {from: dev});
        await this.iso.setLock(this.lock.address, {from: dev});
    });

    beforeEach(async () => {

    });

    it('should set lock up asset properly', async () => {
        await this.lock.setLockUpAsset(alice, {from: dev});
        assert.equal(
            (await this.lock.lockUpAsset()).toString(),
            alice);
    });

    it('should set minimum lock up amount properly', async () => {
        await this.lock.setMinLockUpAmount("1", {from: dev});
        assert.equal(
            (await this.lock.minLockUpAmount()).toString(),
            "1");
    });

    it('should set minimum lock up period properly', async () => {
        await this.lock.setMinLockUpPeriod("1", {from: dev});
        assert.equal(
            (await this.lock.minLockUpPeriod()).toString(),
            "1"
        );
    });

    it('should lock properly', async () => {

        await this.lock.setLockUpAsset(this.base.address, {from: dev});
        await this.lock.setMinLockUpPeriod("1", {from: dev});

        await this.lock.lock({from: alice});

        await expectRevert(
            this.lock.lock({from: alice}),
            "locked"
        );

    });

    it('should unlock properly', async () => {
        await this.lock.setLockUpAsset(this.base.address, {from: dev});
        await this.lock.setMinLockUpPeriod("1", {from : dev});

        await this.lock.lock({from: alice});

        await this.lock.unlock({from: alice});
    });


});