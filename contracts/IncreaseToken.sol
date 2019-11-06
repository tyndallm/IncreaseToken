pragma solidity ^0.5.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/ownership/Ownable.sol";

/**
 * ERC20 Increase Token
 */
contract IncreaseToken is IERC20, Ownable {
    using SafeMath for uint;

    mapping (uint => address) public accounts; // every account with a balance history

    mapping (address => uint) public increaseAccount; // stores increase start times, 0 indicates not increasing account

    mapping (address => uint) public totalReceived;
    mapping (address => uint) public totalSpent;

    mapping (address => mapping (address => uint)) private _allowances;

    uint public totalAccounts = 0;

    uint public constant HOUR_LENGTH_IN_SECONDS = 60 * 60;
    uint public constant DAY_LENTH_IN_SECONDS = HOUR_LENGTH_IN_SECONDS * 24;

    function addIncreaseAccount(address newAccount, uint startUnixTimestamp) public onlyOwner {
        require(increaseAccount[newAccount] == 0, "cannot override existing accounts");

        increaseAccount[newAccount] = startUnixTimestamp;
        accounts[totalAccounts] = newAccount;
        totalAccounts = totalAccounts++;
    }

    function balanceOf(address account) public view returns (uint) {
        // todo does this account for decimals properly - 1e18?
        return daysIncreasing(account) + totalReceived[account] - totalSpent[account];
    }

    function totalSupply() public view returns (uint balance) {
        for (uint i = 0; i < totalAccounts; i++) {
            balance += balanceOf(accounts[i]);
        }
        return balance;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    function daysIncreasing(address account) public view returns (uint) {
        return numDaysForTimestamp(increaseAccount[account]);
    }

    function numDaysForTimestamp(uint accountStart) internal view returns (uint) {
        // todo is using block.timestamp safe for this?
        uint delta = block.timestamp.sub(accountStart);
        return delta.div(DAY_LENTH_IN_SECONDS);
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        // todo check if recipient is in accounts, otherwise set recipient in accounts and increment accounts
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20 transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20 transfer from zero address");
        require(recipient != address(0), "ERC20 transfer to zero address");

        // sender must have balance of at least 'amount'
        require(balanceOf(sender) >= amount, "insufficient balance");

        totalSpent[sender] = totalSpent[sender].add(amount);
        totalReceived[recipient] = totalReceived[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20 approve from zero address");
        require(spender != address(0), "ERC20 approve to zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}