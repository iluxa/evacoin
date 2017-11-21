
var eva_coin = artifacts.require("EvaCoin");
var evc_pre = artifacts.require("EvaCoinPreSale");

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

// Check buying tokens, ether transfer, pay dividends
// test with: testrpc -l 4500000000000
contract('evc_pre_dividends', function(accounts) {
  var a1 = accounts[0];
  var a2 = accounts[1];
  var a3 = accounts[2];
  var a4 = accounts[3];
  var a5 = accounts[4];
  it("should assert true", function() {
    var m;
    var coin;
    var rate;
    var a1Balance = getBalanceEth(a1);

    return evc_pre.deployed().then(function(instance) {
        console.log("deployed");
        m = instance;
        return m.coin.call();
    }).then(function (result) {
        coin = eva_coin.at(result);
        //return m.sendTransaction({from:a2,value:web3.toWei(1)});
        //return 1;
        return coin.owner.call();
    }).then(function (result) {
        assert.equal(result, m.address, "Coin owner must be PreSale contract");
        console.log(result, " == ", m.address);
    }).then(function (result) {
        return coin.keeper.call();
    }).then(function (result) {
        console.log(result, " == ", a1);
        assert.equal(result, a1, "Coin keeper must be a1");
        return m.sendTransaction({from:a2,value:web3.toWei(1)});
    }).then(function (result) {
        return m.sendTransaction({from:a3,value:web3.toWei(2)});
    }).then(function (result) {
        return m.sendTransaction({from:a4,value:web3.toWei(3)});
    }).then(function (result) {
        return coin.totalSupply.call();
    }).then(function (result) {
        var supply = wei2ether(result);
        assert.equal(supply, 1*2000 + 2*2000 + 3*2000, "Total supply must be 12000");
        var bal = getBalanceEth(a1);
        assert.equal(bal - a1Balance, 1 + 2 + 3, "Ethers a1 must be 6 greater");
        return coin.sendDividends(300, {from: a1, value: web3.toWei(12)});
    }).then(function (result) {
        return coin.checkPayments.sendTransaction({from:a2});
    }).then(function (result) {
        return coin.paymentsOf.call({from:a2});
    }).then(function (result) {
        assert.equal(wei2ether(result), 2, "Balance a2 must be 2");
        return coin.checkPayments.sendTransaction({from:a3});
    }).then(function (result) {
        return coin.paymentsOf.call({from:a3});
    }).then(function (result) {
        assert.equal(wei2ether(result), 4, "Balance a3 must be 4");
        return coin.checkPayments.sendTransaction({from:a4});
    }).then(function (result) {
        return coin.paymentsOf.call({from:a4});
    }).then(function (result) {
        assert.equal(wei2ether(result), 6, "Balance a4 must be 6");
        return coin.checkPayments.sendTransaction({from:a5});
    }).then(function (result) {
        return coin.paymentsOf.call({from:a5});
    }).then(function (result) {
        assert.equal(wei2ether(result), 0, "Balance a5 must be 0");

    });

    });
});

// Send bounty tokens, bounty limit
// test with: testrpc -l 4500000000000
contract('evc_pre_bounty', function(accounts) {
  var a1 = accounts[0];
  var a2 = accounts[1];
  var a3 = accounts[2];
  var a4 = accounts[3];
  var a5 = accounts[4];
  it("should assert true", function() {
    var m;
    var coin;
    var rate;

    return evc_pre.deployed().then(function(instance) {
        console.log("deployed");
        m = instance;
        return m.coin.call();
    }).then(function (result) {
        coin = eva_coin.at(result);
        return m.bountyCoinsMax.call();
    }).then(function (result) {
        var bountyMax = wei2ether(result);
        //console.log("bounty: ", bountyMax);
        assert.equal(bountyMax, 75000, "Bounty max must be 75000");
        return m.sendBounty.sendTransaction(a2, 20000);
    }).then(function (result) {
        return coin.balanceOf.call(a2);
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("balance: ", balance);
        assert.equal(balance, 20000, "a2 balance must be 20000");
        return m.sendBounty.sendTransaction(a3, 20000);
    }).then(function (result) {
        return coin.balanceOf.call(a3);
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("balance: ", balance);
        assert.equal(balance, 20000, "a3 balance must be 20000");
        return m.sendBounty.sendTransaction(a4, 20000);
    }).then(function (result) {
        return coin.balanceOf.call(a4);
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("balance: ", balance);
        assert.equal(balance, 20000, "a4 balance must be 20000");
        return m.sendBounty.sendTransaction(a5, 20000);
    }).then(function (result) { 
        assert(false);
        }).catch(function(error) {
            assert.equal(error.message, "VM Exception while processing transaction: revert", "Exception must be generated");
    }).then(function (result) {
        return coin.balanceOf.call(a5);
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("balance: ", balance);
        assert.equal(balance, 0, "a5 balance must be 0");
        return m.bountyCoins.call();
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("bountyCoins: ", balance);
        assert.equal(balance, 60000, "bountyCoins must be 60000");
        return coin.totalSupply.call();
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("totalSupply: ", balance);
        assert.equal(balance, 60000, "totalSupply must be 60000");

    });
});
});

// Send sponsors tokens, sponsors limit
// test with: testrpc -l 4500000000000
contract('evc_pre_sponsors', function(accounts) {
  var a1 = accounts[0];
  var a2 = accounts[1];
  var a3 = accounts[2];
  var a4 = accounts[3];
  var a5 = accounts[4];
  it("should assert true", function() {
    var m;
    var coin;
    var rate;

    return evc_pre.deployed().then(function(instance) {
        console.log("deployed");
        m = instance;
        return m.coin.call();
    }).then(function (result) {
        coin = eva_coin.at(result);
        return m.sponsorsCoinsMax.call();
    }).then(function (result) {
        var sponsorsMax = wei2ether(result);
        //console.log("sponsors: ", sponsorsMax);
        assert.equal(sponsorsMax, 75000, "Sponsors max must be 75000");
        return m.sendSponsors.sendTransaction(a2, 20000);
    }).then(function (result) {
        return coin.balanceOf.call(a2);
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("balance: ", balance);
        assert.equal(balance, 20000, "a2 balance must be 20000");
        return m.sendSponsors.sendTransaction(a3, 20000);
    }).then(function (result) {
        return coin.balanceOf.call(a3);
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("balance: ", balance);
        assert.equal(balance, 20000, "a3 balance must be 20000");
        return m.sendSponsors.sendTransaction(a4, 20000);
    }).then(function (result) {
        return coin.balanceOf.call(a4);
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("balance: ", balance);
        assert.equal(balance, 20000, "a4 balance must be 20000");
        return m.sendSponsors.sendTransaction(a5, 20000);
    }).then(function (result) { 
        assert(false);
        }).catch(function(error) {
            assert.equal(error.message, "VM Exception while processing transaction: revert", "Exception must be generated");
    }).then(function (result) {
        return coin.balanceOf.call(a5);
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("balance: ", balance);
        assert.equal(balance, 0, "a5 balance must be 0");
        return m.sponsorsCoins.call();
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("sponsorsCoins: ", balance);
        assert.equal(balance, 60000, "sponsorsCoins must be 60000");
        return coin.totalSupply.call();
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("totalSupply: ", balance);
        assert.equal(balance, 60000, "totalSupply must be 60000");


    });
});
});

// Check PreSale hardcap, Presale finalization
// test with: testrpc -l 4500000000000
contract('evc_pre_limits', function(accounts) {
  var a1 = accounts[0];
  var a2 = accounts[1];
  var a3 = accounts[2];
  var a4 = accounts[3];
  var a5 = accounts[4];
  it("should assert true", function() {
    var m;
    var coin;
    var rate;
    var a1Balance = getBalanceEth(a1);

    return evc_pre.deployed().then(function(instance) {
        console.log("deployed");
        m = instance;
        return m.coin.call();
    }).then(function (result) {
        coin = eva_coin.at(result);

        return m.sendTransaction({from:a2,value:web3.toWei(30)});
    }).then(function (result) {
        return coin.balanceOf.call(a2);
    }).then(function (result) {
        //console.log("a2 coins: ", wei2ether(result));
        assert.equal(wei2ether(result), 30*2000, "a2 must have 60000 coins");

        return m.sendTransaction({from:a3,value:web3.toWei(30)});
    }).then(function (result) {
        return coin.balanceOf.call(a3);
    }).then(function (result) {
        assert.equal(wei2ether(result), 30*2000, "a3 must have 60000 coins");
        return m.sendTransaction({from:a4,value:web3.toWei(30)});
    }).then(function (result) { 
        assert(false);
        }).catch(function(error) {
            assert.equal(error.message, "VM Exception while processing transaction: revert", "Exception must be generated");
    }).then(function (result) {
        return coin.balanceOf.call(a4);
    }).then(function (result) {
        assert.equal(wei2ether(result), 0, "a4 must have 0 coins");
        return coin.totalSupply.call();
    }).then(function (result) {
        var balance = wei2ether(result);
        //console.log("totalSupply: ", balance);
        assert.equal(balance, 2*30*2000, "totalSupply must be 120000");
        return coin.balanceOf.call(a1);
    }).then(function (result) {
        //console.log("a1 coins: ", wei2ether(result));
        assert.equal(wei2ether(result), 0, "a1 must have 0 coins");
        return m.finalize.sendTransaction();
    }).then(function (result) {
        return coin.balanceOf.call(a1);
    }).then(function (result) {
        //console.log("a1 coins: ", wei2ether(result));
        assert.equal(wei2ether(result), 135000 / 300 * 1000, "a1 after finalize must have 450000 coins");
        return m.sendTransaction({from:a4,value:web3.toWei(1)});
    }).then(function (result) { 
        assert(false);
        }).catch(function(error) {
            assert.equal(error.message, "VM Exception while processing transaction: revert", "Exception must be generated");

    });

    });
});

