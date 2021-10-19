const ISO = artifacts.require('ISO');

contract('ISO test', ([alice, dev]) => {

    beforeEach(async () => {
        this.iso = await ISO.new(dev, {from: dev});
    });

    it('should set admin properly', async () => {
        await this.iso.setAdmin(alice, {from: dev});
        assert.equal(
            (await this.iso.admin()).toString(),
            alice
        );
    });

    it('should set controller properly', async () => {
        await this.iso.setController(alice, {from: dev});
        assert.equal(
            (await this.iso.controller()).toString(),
            alice
        );
    });

    it('should set portfolio factory properly', async () => {
        await this.iso.setFactory(alice, {from: dev});
        assert.equal(
            (await this.iso.factory()).toString(),
            alice
        );
    });

    it('should set lock properly', async () => {
        await this.iso.setLock(alice, {from: dev});
        assert.equal(
            (await this.iso.lock()).toString(),
            alice
        );
    });

    it('should add minter properly', async () => {
        await this.iso.addMinter(alice, {from: dev});
        assert.equal(
            (await this.iso.isMinter(alice)).toString(),
            "true"
        );
    });

    it('should mint properly', async () => {
        await this.iso.addMinter(dev, {from: dev});
        await this.iso.mint(alice, "1", {from: dev});
        assert.equal(
            (await this.iso.balanceOf(alice)).toString(),
            "1"
        );
    });

    it('should burn properly', async () => {
        await this.iso.addMinter(dev, {from: dev});
        await this.iso.mint(alice, "1", {from: dev});
        await this.iso.burn("1", {from: alice});
        assert.equal(
            (await this.iso.balanceOf(alice)).toString(),
            "0"
        );
    });
});