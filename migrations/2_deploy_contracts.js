const Controller = artifacts.require('Controller');
const Factory = artifacts.require('Factory');
const ISO = artifacts.require('ISO');
const Lock = artifacts.require('Lock');
const Viewer = artifacts.require('Viewer');

const MockERC20 = artifacts.require('MockBEP20');

module.exports = function (deployer) {


    /*
    let isoInstance;
    deployer.deploy(ISO, "0x17142514BBb117aa14B80e081eC4423770cCB464").then(function(instance) {
        isoInstance = instance;
        return deployer.deploy(Factory);
    }).then(function() {
        return deployer.deploy(Lock, ISO.address);
    }).then(function() {
        return deployer.deploy(Controller, ISO.address);
    }).then(function() {
        return deployer.deploy(Viewer, ISO.address);
    }).then(function() {
        return isoInstance.setFactory(Factory.address);
    }).then(function() {
        return isoInstance.setLock(Lock.address);
    }).then(function() {
        return isoInstance.setController(Controller.address);
    }).catch(function(error) {
        console.log(error);
    });

     */


    deployer.deploy(MockERC20, "KDR", "KDR", "1000000000000000000").then(function() {
        return deployer.deploy(Lock, "0x8d24c23c6d68bac9394a22401cbcfecf62d9227e");
    }).catch(function(error) {
        console.log(error);
    })

};
