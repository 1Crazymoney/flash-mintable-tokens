pragma solidity 0.5.16;

interface IFlashWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function flashMint(uint256) external;
}