pragma solidity 0.5.16;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/SafeERC20.sol";
import "./IFlashWETH.sol";

// @title Exchange
// @notice A constant-sum market for ETH and fWETH
contract Exchange {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address constant public fWETH = address(0); // address of FlashWETH contract

    // users get "credits" for depositing ETH or fWETH
    // credits can be redeemed for an equal number of ETH or fWETH
    // e.g.: You can deposit 5 fWETH to get 5 "credits", and then immediately use those credits to
    // withdrawl 5 ETH.
    mapping (address => uint256) public credits;

   // fallback must be payable and empty to receive ETH from the FlashWETH contract
    function () external payable {}

    // ==========
    //  DEPOSITS
    // ==========

    // Gives depositor credits for ETH
    function depositETH() public payable {
        credits[msg.sender] = credits[msg.sender].add(msg.value);
    }

    // Gives depositor credits for fWETH
    function depositFWETH(uint256 amount) public payable {
        ERC20(fWETH).safeTransferFrom(msg.sender, address(this), amount);
        credits[msg.sender] = credits[msg.sender].add(amount);
    }

    // =============
    //  WITHDRAWALS
    // =============

    // Redeems credits for ETH
    function withdrawETH(uint256 amount) public {
        credits[msg.sender] = credits[msg.sender].sub(amount);
        // if the contract doesn't have enough ETH then try to get some
        uint256 ethBalance = address(this).balance;
        if (amount > ethBalance) {
            internalSwapToETH(amount.sub(ethBalance));
        }
        msg.sender.transfer(amount);
    }

    // Redeems credits for fWETH
    function withdrawFWETH(uint256 amount) public {
        credits[msg.sender] = credits[msg.sender].sub(amount);
        // if the contract doesn't have enough fWETH then try to get some
        uint256 fWethBalance = ERC20(fWETH).balanceOf(address(this));
        if (amount > fWethBalance) {
            internalSwapToFWETH(amount.sub(fWethBalance));
        }
        ERC20(fWETH).safeTransfer(msg.sender, amount);
    }

    // ===================
    //  INTERNAL EXCHANGE
    // ===================

    // Forces this contract to convert some of its own fWETH to ETH
    function internalSwapToETH(uint256 amount) public {
        // redeem fWETH for ETH via the FlashWETH contract
        IFlashWETH(fWETH).withdraw(amount);
    }

    // Forces this contract to convert some of its own ETH to fWETH
    function internalSwapToFWETH(uint256 amount) public {
        // deposit ETH for fWETH via the FlashWETH contract
        IFlashWETH(fWETH).deposit.value(amount)();
    }

    // =========
    //  GETTERS
    // =========

    function ethBalance() external view returns (uint256) { return address(this).balance; }
    function fwethBalnce() external view returns (uint256) { return ERC20(fWETH).balanceOf(address(this)); }

}

// note: sum of all credits should be at most address(this).balance.add(ERC20(fWETH).balanceOf(address(this)));