var evacoin = artifacts.require("EvaCoin")
var evacoin_pre = artifacts.require("EvaCoinPreSale")

module.exports = function(deployer, network, accounts) {
    var a1 = accounts[0];
    var coin;

    var now = Date.now() / 1000;
    deployer.deploy(evacoin).then(function() {
        return evacoin.deployed().then(function(c) {
            coin = c;
            return deployer.deploy(evacoin_pre, coin.address, now , now + 3*86400).then(function() {
                return evacoin_pre.deployed().then(function(epre) {
                    return coin.transferOwnership(epre.address, {from: a1}).then(function() {
                        return coin.owner.call().then(function(result) {
                        });
                    });
                });
            });
        });
    });
}
