var eva_coin = artifacts.require("EvaCoin");
var evc_pre = artifacts.require("EvaCoinPreSale");
var evc_sale1 = artifacts.require("EvaCoinSale1");
var evc_sale2 = artifacts.require("EvaCoinSale2");

function getBalanceEth(x) {
  return Math.round(web3.fromWei(web3.eth.getBalance(x), 'ether'));
}

function wei2ether(x) {
    return web3.fromWei(x,'ether').toNumber();
}

function getBalanceEthSum(x) {
    var sum = web3.fromWei(web3.eth.getBalance(x[0]), 'ether');
    for (var i = 1; i < x.length; i++) {
        sum = sum.plus(web3.fromWei(web3.eth.getBalance(x[i]), 'ether'));
    }

    return Math.round(sum);
}

contract('evc_sale1', function(accounts) {
  var a1 = accounts[0];
  var a2 = accounts[1];
  var a3 = accounts[2];
  var a4 = accounts[3];
  var a5 = accounts[4];
  var a6 = accounts[5];
  var a7 = accounts[6];
  var a8 = accounts[7];
  var a9 = accounts[8];
  it("should assert true", function() {
    var m;
    var coin;
    var rate;
    var supply;
    var sale2;
    var balance;
    var cap;
    var a1Balance = getBalanceEth(a1);

    return evc_pre.deployed().then(function(instance) {
        //console.log("presale deployed");
        m = instance;
        return m.finalize.sendTransaction();
    }).then(function (result) {
        return evc_sale1.deployed().then(function(instance) {
        //console.log("sale deployed");
        m = instance;
        return m.coin.call();
    }).then(function (result) {
        coin = eva_coin.at(result);
        return coin.owner.call();
    }).then(function (result) {
        assert.equal(result, a1, "Coin owner must be a1");
        //console.log(result, " == ", a1);
    }).then(function (result) {
        return coin.keeper.call();
    }).then(function (result) {
        //console.log(result, " == ", a1);
        assert.equal(result, a1, "Coin keeper must be a1");
        return coin.transferOwnership(m.address);
    }).then(function (result) {
        //console.log("ownership transfered to sale1");
        return m.start.sendTransaction({from: a1});
    }).then(function (result) {
        console.log("started");
        return coin.totalSupply.call();
    }).then(function (result) {
        supply = wei2ether(result);
        return m.sendTransaction({from:a2,value:web3.toWei(1)});
    }).then(function (result) {
        return coin.balanceOf.call(a2);
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("balance: ", balance);
        assert.equal(balance, 1000 * 1.5, "a2 balance must be 1500");
        return m.sendTransaction({from:a3,value:web3.toWei(2)});
    }).then(function (result) {
        return m.sendTransaction({from:a4,value:web3.toWei(3)});
    }).then(function (result) {
        return m.sendTransaction({from:a5,value:web3.toWei(99)});
    }).then(function (result) {
        return m.sendTransaction({from:a6,value:web3.toWei(99)});
    }).then(function (result) {
        return m.sendTransaction({from:a7,value:web3.toWei(99)});
    }).then(function (result) {
        return m.sendTransaction({from:a8,value:web3.toWei(99)});
    }).then(function (result) {
        return m.sendTransaction({from:a9,value:web3.toWei(99)});
    }).then(function (result) {
        return coin.totalSupply.call();
    }).then(function (result) {
        supply = wei2ether(result);
        return coin.raisedSale1USD.call();
    }).then(function (result) {
        //console.log("raisedSale1: ", result.toNumber());
        return m.finalize.sendTransaction();
    }).then(function (result) {
        return m.bountyCoinsMax.call();
    }).then(function (result) {
        var bounty = wei2ether(result);
        //console.log("bounty: ", bounty);
        assert.equal(bounty, supply * 0.03, "bounty max must be 3%");
        return m.sponsorsCoinsMax.call();
    }).then(function (result) {
        var sponsors = wei2ether(result);
        //console.log("sponsors: ", sponsors);
        assert.equal(sponsors, supply * 0.03, "sponsors max must be 3%");
        return m.sendBounty.sendTransaction(a2, supply * 0.03);
    }).then(function (result) {
        return m.bountyCoins.call();
    }).then(function (result) {
        var bounty = wei2ether(result);
        //console.log("bounty: ", bounty);
        assert.equal(bounty, supply * 0.03, "bounty max must be 3%");
        return m.sendSponsors.sendTransaction(a2, supply * 0.03);
    }).then(function (result) {
        return m.sponsorsCoins.call();
    }).then(function (result) {
        var sponsors = wei2ether(result);
        //console.log("sponsors: ", sponsors);
        assert.equal(sponsors, supply * 0.03, "sponsors max must be 3%");
        var bal = getBalanceEth(a1);
        //console.log("balance a1: ", bal);
        return coin.sendDividends(300, {from: a1, value: web3.toWei(550)});
    }).then(function (result) {
        //console.log("dividends sent");
        var now = Date.now() / 1000;
        return m.startSale2(30000, now, now + 5*86400);
    }).then(function (result) {
        //console.log("sale2 created: ");
        return m.sale2.call();
    }).then(function (result) {
        sale2 = evc_sale2.at(result);
        return sale2.start.sendTransaction();
    }).then(function (result) {
        return sale2.cap.call();
    }).then(function (result) {
        cap = wei2ether(result);
        //console.log("sale2 started cap: ", cap);
        return coin.balanceOf.call(a2);
    }).then(function (result) {
        balance = wei2ether(result);
        return sale2.sendTransaction({from:a2,value:web3.toWei(cap)});
    }).then(function (result) {
        //console.log("a2 sent");
        return coin.balanceOf.call(a2);
    }).then(function (result) {
        var bal = wei2ether(result);
        //console.log("balance diff: ", bal - balance);
        assert.equal(bal - balance, cap * 1000 * 1.2 , "a2 balance inc should be 20% higher");
        return sale2.finalize.sendTransaction();
    }).then(function (result) {
        //console.log("sale2 finalized");
    });
    });
});
});
