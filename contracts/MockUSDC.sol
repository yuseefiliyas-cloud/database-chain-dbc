// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "mUSDC") {
        // Mint 10,000,000 test USDC to your wallet for liquidity & testing
        _mint(msg.sender, 10_000_000 * 10**18);
    }

    function mintMore(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
