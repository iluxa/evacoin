pragma solidity ^0.4.11;

import "./evacoin.sol";
import "./evacoin_pre.sol";
import 'zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol';
import 'zeppelin-solidity/contracts/crowdsale/RefundableCrowdsale.sol';

contract EvaCoinSale1 is CappedCrowdsale, RefundableCrowdsale {

    // ETH/USD exchange rate - set to actual before contract deploy
    uint256 public constant ETH_RATE = 300;  

    uint256 public SALE_RATE; // corresponded constant from PreSale

    // How much want to raise in USD
    uint256 public constant RAISE_USD_SOFT = 150 * 1000; // $150K soft cap
    uint256 public constant RAISE_USD_HARD = 750 * 1000; // $750K hard cap

    // soft cap and hard cap in wei
    uint256 public constant SOFT_CAP = RAISE_USD_SOFT * 1 ether / ETH_RATE;
    uint256 public constant HARD_CAP = RAISE_USD_HARD * 1 ether / ETH_RATE;

    // 20% coins for 50% SALE
    uint256 public constant HARD_CAP_50_SALE = HARD_CAP / 5;

    // 30% coins for 25% SALE
    uint256 public constant HARD_CAP_25_SALE = HARD_CAP * 3 / 10;

    // How much want to send on bounty program
    uint256 public bountyCoinsMax;
    uint256 public bountyCoins;

    // How much want to send for sponsors program
    uint256 public sponsorsCoinsMax;
    uint256 public sponsorsCoins;

    EvaCoin public coin;
    EvaCoinPreSale public presale;
    EvaCoinSale2 public sale2;

    function EvaCoinSale1(address _presale, uint256 _startTime, uint256 _endTime)
        CappedCrowdsale(HARD_CAP)
        FinalizableCrowdsale()
        RefundableCrowdsale(SOFT_CAP)
        Crowdsale(_startTime, _endTime, EvaCoinPreSale(_presale).SALE_RATE(), msg.sender)
    {
        presale = EvaCoinPreSale(_presale);
        coin = presale.coin();

        // Need to call this, because wrong token assigned in CrowdSale constructor
        Crowdsale.token = coin;

        SALE_RATE = presale.SALE_RATE();
    }

    // coin ownership must be transfered to this contract before start() call
    function start() onlyOwner public {
        coin.sale1Started();
    }

    function is50SaleActive() public constant returns (bool) {
        return now - startTime < 24 hours && weiRaised < HARD_CAP_50_SALE;
    }
    function is25SaleActive() public constant returns (bool) {
        return now - startTime < 48 hours && weiRaised < (HARD_CAP_50_SALE + HARD_CAP_25_SALE);
    }

    // Override Crowdsale#buyTokens
    function buyTokens(address beneficiary) public payable {
        require(coin.stage() == EvaCoin.SaleStages.Sale1);
        require(msg.value >= 10 finney);
        if ( is50SaleActive() ) {
            rate = SALE_RATE * 15 / 10; // + 50%
        } else if ( is25SaleActive() ) {
            rate = SALE_RATE * 125 / 100; // +25%
        } else {
            rate = SALE_RATE;
        }
        super.buyTokens(beneficiary);
        coin.raisedUSD(ETH_RATE.mul(msg.value).div(1 ether));
    }

    // Override Crowdsale#hasEnded
    function hasEnded() public constant returns (bool) {
        return goalReached();
    }

    // Override FinalizableCrowdsale#finalization
    // It is onlyOwner protected by calling function
    function finalization() internal {
        require(coin.stage() == EvaCoin.SaleStages.Sale1);
        coin.allowTransfer();

        bountyCoinsMax = coin.totalSupply() * 3 / 100; // 3% of totalSupply for bounty
        sponsorsCoinsMax = coin.totalSupply() * 3 / 100; // 3% of totalSupply for sponsors

        RefundableCrowdsale.finalization();
    }

    function createTokenContract() internal returns (MintableToken) {
        return coin;
    }

    // send couns for bounty, value in integer coins
    function sendBounty(address to, uint256 value) onlyOwner public {
        uint256 coinValue = value.mul(uint256(10)**coin.decimals());
        require (bountyCoins + coinValue <= bountyCoinsMax);
        bountyCoins = bountyCoins.add(coinValue);
        coin.mint(to, coinValue);
    }

    // send couns for sponsors, value in integer coins
    function sendSponsors(address to, uint256 value) onlyOwner public {
        uint256 coinValue = value.mul(uint256(10)**coin.decimals());
        require (sponsorsCoins + coinValue <= sponsorsCoinsMax);
        sponsorsCoins = sponsorsCoins.add(coinValue);
        coin.mint(to, coinValue);
    }

    function startSale2(uint256 ethusd, uint256 _startTime, uint256 _endTime) onlyOwner public {
        require(isFinalized);
        require(coin.canStartSale2());
        require(coin.stage() == EvaCoin.SaleStages.Sale1);

        sale2 = new EvaCoinSale2(this, ethusd, _startTime, _endTime);

        //Transfer coin ownership to Sale2 contract
        coin.transferOwnership(sale2);
    }
}

contract EvaCoinSale2 is CappedCrowdsale, FinalizableCrowdsale {
    // Actual ETH/USD rate - constructor parameter
    uint256 public ETH_RATE;

    // corresponded value from PreSale / Sale1
    uint256 public SALE_RATE;

    // 10% coins for 20% SALE
    uint256 public HARD_CAP_20_SALE;

    // 20% coins for 10% SALE
    uint256 public HARD_CAP_10_SALE;

    EvaCoin coin;
    EvaCoinSale1 sale1;

    function EvaCoinSale2(address _sale1, uint256 ethusd, uint256 _startTime, uint256 _endTime)
        CappedCrowdsale(
            (EvaCoinSale1(_sale1).coin().raisedPreSaleUSD() + EvaCoinSale1(_sale1).coin().raisedSale1USD()).mul(10).mul(1 ether) / ethusd)
        FinalizableCrowdsale()
        Crowdsale(_startTime, _endTime, EvaCoinSale1(_sale1).SALE_RATE(), EvaCoinSale1(_sale1).coin().keeper())
    {
        sale1 = EvaCoinSale1(_sale1);
        ETH_RATE = ethusd;
        coin = EvaCoin(sale1.coin());

        SALE_RATE = sale1.SALE_RATE();

        // 10% coins for 20% SALE
        HARD_CAP_20_SALE = cap / 10;

        // 20% coins for 10% SALE
        HARD_CAP_10_SALE = cap / 5;

        // Need to call this, because wrong token assigned in CrowdSale constructor
        Crowdsale.token = coin;

        //transfer contract ownership to Sale1 contract ownership
        transferOwnership(coin.keeper());
    }

    // coin ownership must be transfered to this contract before start() call
    function start() onlyOwner public {
        coin.sale2Started();
    }

    // Override Crowdsale#createTokenContract
    function createTokenContract() internal returns (MintableToken) {
        return coin;
    }

    function is20SaleActive() public constant returns (bool) {
        return now - startTime < 48 hours && weiRaised < HARD_CAP_20_SALE;
    }
    function is10SaleActive() public constant returns (bool) {
        return now - startTime < 96 hours && weiRaised < (HARD_CAP_10_SALE + HARD_CAP_20_SALE);
    }

    // Override buyTokens function from Crowdsale
    function buyTokens(address beneficiary) public payable {
        require(coin.stage() == EvaCoin.SaleStages.Sale2);
        require(msg.value >= 10 finney);
        if ( is20SaleActive() ) {
            rate = SALE_RATE * 120 / 100; // + 20%
        } else if ( is10SaleActive() ) {
            rate = SALE_RATE * 110 / 100; // +10%
        } else {
            rate = SALE_RATE;
        }
        super.buyTokens(beneficiary);
        coin.raisedUSD(ETH_RATE.mul(msg.value).div(1 ether));
    }

    // Override FinalizableCrowdsale#finalization
    // It is onlyOwner protected by calling function
    function finalization() internal {
        coin.sale2Stopped();

        // 5% coins for team
        coin.mint(coin.keeper(), (coin.raisedSale2USD() / ETH_RATE).mul(SALE_RATE) / 20);

        // sale2 still owns coin, so coin is frozen
    }
}

