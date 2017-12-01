pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/token/MintableToken.sol';
import 'zeppelin-solidity/contracts/payment/PullPayment.sol';

contract EvaCoin is MintableToken, PullPayment {
    string public constant name = "EvaCoin";
    string public constant symbol = "EVA";
    uint8 public constant decimals = 18;
    bool public transferAllowed = false;

    // keeper has special limited rights for the coin:
    // pay dividends
    address public keeper;

    // raisings in USD
    uint256 public raisedPreSaleUSD;
    uint256 public raisedSale1USD;
    uint256 public raisedSale2USD;
    uint256 public payedDividendsUSD;

    // coin issues
    uint256 public totalSupplyPreSale = 0;
    uint256 public totalSupplySale1 = 0;
    uint256 public totalSupplySale2 = 0;

    enum SaleStages { PreSale, Sale1, Sale2, SaleOff }
    SaleStages public stage = SaleStages.PreSale;

    function EvaCoin() public {
        keeper = msg.sender; 
    }   

    modifier onlyKeeper() {
        require(msg.sender == keeper);
        _;
    }

    function sale1Started() onlyOwner public {
        totalSupplyPreSale = totalSupply;
        stage = SaleStages.Sale1;
    }
    function sale2Started() onlyOwner public {
        totalSupplySale1 = totalSupply;
        stage = SaleStages.Sale2;
    }
    function sale2Stopped() onlyOwner public {
        totalSupplySale2 = totalSupply;
        stage = SaleStages.SaleOff;
    }

    // ---------------------------- dividends related definitions --------------------
    uint constant MULTIPLIER = 10e18;

    mapping(address=>uint256) lastDividends;
    uint public totalDividendsPerCoin;
    uint public etherBalance;

    modifier activateDividends(address account) {
        if (totalDividendsPerCoin != 0) { // only after first dividends payed
            var actual = totalDividendsPerCoin - lastDividends[account];
            var dividends = (balances[account] * actual) / MULTIPLIER;

            if (dividends > 0 && etherBalance >= dividends) {
                etherBalance -= dividends;
                lastDividends[account] = totalDividendsPerCoin;
                asyncSend(account, dividends);
            }
            //This needed for accounts with zero balance at the moment
            lastDividends[account] = totalDividendsPerCoin;
        }

        _;
    }
    function activateDividendsFunc(address account) private activateDividends(account) {}
    // -------------------------------------------------------------------------------


    // ---------------------------- sale 2 bonus definitions --------------------
    // coins investor has before sale2 started
    mapping(address=>uint256) sale1Coins;

    // investors who has been payed sale2 bonus
    mapping(address=>bool) sale2Payed;

    modifier activateBonus(address account) {
        if (stage == SaleStages.SaleOff && !sale2Payed[account]) {
            uint256 coins = sale1Coins[account];
            if (coins == 0) {
                coins = balances[account];
            }
            balances[account] += balances[account] * coins / (totalSupplyPreSale + totalSupplySale1);
            sale2Payed[account] = true;
        } else if (stage != SaleStages.SaleOff) {
            // remember account balace before SaleOff
            sale1Coins[account] = balances[account];
        }
        _;
    }
    function activateBonusFunc(address account) private activateBonus(account) {}

    // ----------------------------------------------------------------------

    event TransferAllowed(bool);

    modifier canTransfer() {
        require(transferAllowed);
        _;
    }

    // Override StandardToken#transferFrom
    function transferFrom(address from, address to, uint256 value) canTransfer
    // stack too deep to call modifiers
    // activateDividends(from) activateDividends(to) activateBonus(from) activateBonus(to)
    public returns (bool) {
        activateDividendsFunc(from);
        activateDividendsFunc(to);
        activateBonusFunc(from);
        activateBonusFunc(to);
        return super.transferFrom(from, to, value); 
    }   
    
    // Override BasicToken#transfer
    function transfer(address to, uint256 value) 
    canTransfer activateDividends(to) activateBonus(to)
    public returns (bool) {
        return super.transfer(to, value); 
    }

    function allowTransfer() onlyOwner public {
        transferAllowed = true; 
        TransferAllowed(true);
    }

    function raisedUSD(uint256 amount) onlyOwner public {
        if (stage == SaleStages.PreSale) {
            raisedPreSaleUSD += amount;
        } else if (stage == SaleStages.Sale1) {
            raisedSale1USD += amount;
        } else if (stage == SaleStages.Sale2) {
            raisedSale2USD += amount;
        } 
    }

    function canStartSale2() constant returns (bool) {
        return payedDividendsUSD >= raisedPreSaleUSD + raisedSale1USD;
    }

    // Dividents can be payed any time - even after PreSale and before Sale1
    // ethrate - actual ETH/USD rate
    function sendDividends(uint256 ethrate) payable onlyKeeper {
        require(totalSupply > 0); // some coins must be issued
        totalDividendsPerCoin += (msg.value * MULTIPLIER / totalSupply);
        etherBalance += msg.value;
        payedDividendsUSD += msg.value * ethrate / 1 ether;
    }

    // Override MintableToken#mint
    function mint(address _to, uint256 _amount) 
        onlyOwner canMint activateDividends(_to) activateBonus(_to) 
        public returns (bool) {
        super.mint(_to, _amount);

        if (stage == SaleStages.PreSale) {
            totalSupplyPreSale += _amount;
        } else if (stage == SaleStages.Sale1) {
            totalSupplySale1 += _amount;
        } else if (stage == SaleStages.Sale2) {
            totalSupplySale2 += _amount;
        } 
    }

    // Override PullPayment#withdrawPayments
    function withdrawPayments()
        activateDividends(msg.sender) activateBonus(msg.sender)
        public {
        super.withdrawPayments();
    }

    function checkPayments()
        activateDividends(msg.sender) activateBonus(msg.sender)
        public returns (uint256) {
        return payments[msg.sender];
    }
    function paymentsOf() constant public returns (uint256) {
        return payments[msg.sender];
    }

    function checkBalance()
        activateDividends(msg.sender) activateBonus(msg.sender)
        public returns (uint256) {
        return balanceOf(msg.sender);
    }

    // withdraw ethers if contract has more ethers
    // than for dividends for some reason
    function withdraw() onlyOwner public {
        if (this.balance > etherBalance) {
            owner.transfer(this.balance - etherBalance);
        }
    }

}
