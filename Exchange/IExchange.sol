pragma solidity 0.5.16;
interface IExchange {
    function depositETH() external;
    function depositFWETH(uint256) external;
    function withdrawETH(uint256) external;
    function withdrawFWETH(uint256) external;
    function internalSwapToETH(uint256) external;
    function internalSwapToFWETH(uint256) external;
    function ethBalance() external returns (uint256);
    function fwethBalance() external returns (uint256);
}