var evacoin = artifacts.require("EvaCoin")
var evacoin_pre = artifacts.require("EvaCoinPreSale")
var evacoin_ico = artifacts.require("EvaCoinSale1")

module.exports = function(deployer, network, accounts) {
    var a1 = accounts[0];
    var coin;
    var pre;

    var now = Date.now() / 1000;
    //return deployer.deploy(evacoin_ico, 0, now, now + 3*86400);
    deployer.deploy(evacoin).then(function() {
        return evacoin.deployed().then(function(c) {
            coin = c;
            return deployer.deploy(evacoin_pre, coin.address, now , now + 3*86400).then(function() {
                return evacoin_pre.deployed().then(function(epre) {
                    pre = epre;
                    return coin.transferOwnership(epre.address, {from: a1}).then(function() {
                        return deployer.deploy(evacoin_ico, pre.address, now, now + 3*86400).then(function(result) { });
                    });
                });
            });
        });
    });

}