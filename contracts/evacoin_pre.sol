pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/crowdsale/Crowdsale.sol';

import 'zeppelin-solidity/contracts/token/MintableToken.sol';
import 'zeppelin-solidity/contracts/payment/PullPayment.sol';

// Abstract interface for the coin
contract EvaCoinBase is MintableToken, PullPayment {
    string public constant name = 'EvaCoin';
    string public constant symbol = 'EVA';
    uint8 public constant decimals = 18;

    // totalSupply before Sale2 started
    uint256 public totalSupplySale1 = 0;

    function raisedUSD(uint256 amount) onlyOwner public;
}

// This derive needed to call setToken
// after constructor work
contract EvaCrowdsale is Crowdsale {

    function EvaCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public
        Crowdsale(_startTime, _endTime, _rate, _wallet)
        {}
        
    function setToken(MintableToken _token) public {
        token = _token;
    }
}

// It is a copy of zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol
// needed to derive EvaCrowdsale
contract EvaCappedCrowdsale is EvaCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function EvaCappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }
}

contract EvaCoinPreSale is EvaCappedCrowdsale, Ownable {
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

    // How much want to send on bounty program
    uint256 public constant BOUNTY_USD = 22500;
    uint256 public bountyCoinsMax;
    uint256 public bountyCoins;

    // How much want to send for sponsors program
    uint256 public constant SPONSORS_USD = 22500;
    uint256 public sponsorsCoinsMax;
    uint256 public sponsorsCoins;

    // hard cap in wei
    uint256 public constant HARD_CAP = RAISE_USD * 1 ether / ETH_RATE;

    // early founders investments in ethers
    uint256 public constant EARLY_FOUNDERS_CAP = EARLY_FOUNDERS_USD * 1 ether / ETH_RATE;

    bool public isFinalized = false;

    EvaCoinBase public coin;

    function EvaCoinPreSale(address evacoin, uint256 _startTime, uint256 _endTime) public
        EvaCappedCrowdsale(HARD_CAP)
        EvaCrowdsale(_startTime, _endTime, PRESALE_RATE, msg.sender)
    {
        coin = EvaCoinBase(evacoin);
        // Need to call this, becaus wrong token assigned in CrowdSale constructor
        setToken(coin);

        bountyCoinsMax = uint256(BOUNTY_USD) * (uint256(10)**coin.decimals()) / ETH_RATE * SALE_RATE;
        sponsorsCoinsMax = uint256(SPONSORS_USD) * (uint256(10)**coin.decimals()) / ETH_RATE * SALE_RATE;
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
        coin.raisedUSD(ETH_RATE * msg.value / 1 ether);
    }

    function finalize() onlyOwner public {
        require(!isFinalized);
        //require(hasEnded());

        // coins for early founders
        uint256 founderCoins = EARLY_FOUNDERS_CAP * SALE_RATE;
        coin.mint(owner, founderCoins);

        // contract owner need to transfer coin to Sale1
        coin.transferOwnership(owner);

        isFinalized = true;
    }

    // send couns for bounty, value in integer coins
    function sendBounty(address to, uint256 value) onlyOwner public {
        uint256 coinValue = value * (uint256(10)**coin.decimals());
        require (bountyCoins + coinValue < bountyCoinsMax);
        bountyCoins = bountyCoins.add(coinValue);
        coin.mint(to, coinValue);
    }

    // send couns for sponsors, value in integer coins
    function sendSponsors(address to, uint256 value) onlyOwner public {
        uint256 coinValue = value * (uint256(10)**coin.decimals());
        require (sponsorsCoins + coinValue < sponsorsCoinsMax);
        sponsorsCoins = sponsorsCoins.add(coinValue);
        coin.mint(to, coinValue);
    }

}
