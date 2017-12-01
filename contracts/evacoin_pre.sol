pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol';

import './evacoin.sol';
import 'zeppelin-solidity/contracts/payment/PullPayment.sol';

contract EvaCoinPreSale is CappedCrowdsale, Ownable {
    // Sale1 and Sale2 EVC/ETH sale rate (without bonus)
    uint256 public constant SALE_RATE = 1000;

    // PreSale EVA/ETH sale rate
    uint256 public constant PRESALE_RATE = 2*SALE_RATE;

    // ETH/USD exchange rate - set to actual before this contract deploy
    uint256 constant ETH_RATE = 300;  

    // How much want to raise in USD
    uint256 constant RAISE_USD = 25000;

    // USD amount invested by early founders before the coin issued in USD
    uint256 public constant EARLY_FOUNDERS_USD = 135 * 1000;

    // hard cap in wei
    uint256 public constant HARD_CAP = RAISE_USD * 1 ether / ETH_RATE;

    // early founders investments in ethers
    uint256 public constant EARLY_FOUNDERS_CAP = EARLY_FOUNDERS_USD * 1 ether / ETH_RATE;

    bool public isFinalized = false;

    EvaCoin public coin;

    function EvaCoinPreSale(address evacoin, uint256 _startTime, uint256 _endTime) public
        CappedCrowdsale(HARD_CAP)
        Crowdsale(_startTime, _endTime, PRESALE_RATE, msg.sender)
    {
        coin = EvaCoin(evacoin);

        // Need to call this, because wrong token assigned in Crowdsale constructor
        Crowdsale.token = coin;
    }

    function createTokenContract() internal returns (MintableToken) {
        // it doesn't really matter what coin to return
        // because setCoin call goes after
        return coin;
    }

    // Override Crowdsale#buyTokens
    function buyTokens(address beneficiary) public payable {
        require(!isFinalized);
        require(msg.value >= 1 ether);
        super.buyTokens(beneficiary);
        coin.raisedUSD(ETH_RATE.mul(msg.value).div(1 ether));
    }

    function finalize() onlyOwner public {
        require(!isFinalized);

        // coins for early founders
        uint256 founderCoins = EARLY_FOUNDERS_CAP.mul(SALE_RATE);
        coin.mint(owner, founderCoins);

        // contract owner need to transfer coin to Sale1 contract
        coin.transferOwnership(coin.keeper());

        isFinalized = true;
    }
}
