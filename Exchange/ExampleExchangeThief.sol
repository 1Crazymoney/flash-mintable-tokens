pragma solidity 0.5.16;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.3.0/contracts/ownership/Ownable.sol";
import "./IFlashWETH.sol";
import "./IExchange.sol";

// @title ExampleExchangeThief
// @notice An example contract that "exploits" the fact that the Exchange contract accepts
// unbacked fWETH during flash-mints in exchange for ETH.
// @dev This is just a boilerplate example to get bug-bounty hunters up and running.
// @dev This contract flash-mints unbacked fWETH and uses it to buy all of the Exchange's ETH.
// But since flash-minting requires burning the same number of fWETH that you minted, the fWETH held by the 
// Exchange end's up being fully backed by real ETH. So there is no actual "theft" happening here.
contract ExampleExchangeThief is Ownable {

    IFlashWETH fWETH = IFlashWETH(0xf7705C1413CffCE6CfC0fcEfe3F3A12F38CB29dA); // address of FlashWETH contract
    IExchange exchange = IExchange(0x5d84fC93A6a8161873a315C233Fbd79A88280079); // address of Exchange contract

    // required to receive ETH in case you want to `withdraw` some fWETH for real ETH during `executeOnFlashMint`
    function () external payable {}

    // call this function to fire off your flash mint
    function beginFlashMint() public payable onlyOwner {
        // We are going to use a flash-mint to "steal" all the ETH from the exchange
        // First, rebalance the exchange so that it is holding the maximum amount of ETH:
        exchange.internalSwapToETH(exchange.fwethBalance());
        // Second, we'll flash-mint enough fWETH to "steal" all the ETH in the exchange:
        fWETH.flashMint(exchange.ethBalance()); // this triggers the `executeOnFlashMint` function below
    }

    // this is what executes during your flash mint
    function executeOnFlashMint(uint256 amount) external {
        // when this fires off, this contract holds `amount` new, unbacked fWETH
        require(msg.sender == address(fWETH), "only FlashWETH can execute");
        // Third, we'll deposit our unbacked fWETH into the exchange:
        fWETH.approve(address(exchange), amount);
        exchange.depositFWETH(amount);
        // Fourth, we'll withdraw all the ETH from the exchange to this contract
        exchange.withdrawETH(amount);
        // YAY! We "stole" all the ETH from the exchange!!! Those suckers accepted unbacked fWETH and gave us all their ETH!
        // However, our transaction will fail unless we burn `amount` fWETH by the end of this transaction.
        // But we don't have any fWETH because we already sent it all to the exchange.
        // That's okay, we can get some more fWETH from the FlashWETH contract by sending it some of our ETH:
        fWETH.deposit.value(amount)();
        // Cool, now this contract holds the amount of fWETH needed to complete the transaction.
        // (Unfortunately, it cost us all of the ETH we "stole" from the exchange contract, so we ended up breaking even)
        // (And now all the fWETH that the exchange contract is holding is backed by real ETH. So I guess we really didn't "steal" anything.)
    }

    // ========================
    //  BASIC WALLET FUNCTIONS
    // ========================

    function withdrawMyETH() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawMyFWETH() public onlyOwner {
        fWETH.transfer(msg.sender, fWETH.balanceOf(address(this)));
    }

    // =========
    //  GETTERS
    // =========

    function ethBalance() external view returns (uint256) { return address(this).balance; }
    function fwethBalance() external view returns (uint256) { return fWETH.balanceOf(address(this)); }
}