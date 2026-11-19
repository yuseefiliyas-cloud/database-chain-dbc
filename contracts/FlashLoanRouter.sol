// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IFlashLoanReceiver {
    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external returns (bool);
}

contract FlashLoanRouter is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant FLASH_LOAN_FEE_BPS = 0; // 0.00% flash loan fee

    event LiquidityDeposited(address indexed provider, address indexed token, uint256 amount);
    event FlashLoanExecuted(address indexed borrower, address indexed token, uint256 amount);

    // Deposit DBC or mUSDC into the router so arbitrage bots have funds to borrow
    function depositLiquidity(address token, uint256 amount) external nonReentrant {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be > 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit LiquidityDeposited(msg.sender, token, amount);
    }

    // Check how much liquidity is available to borrow for a specific token
    function availableLiquidity(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    // Execute an instant, 0.00% fee atomic flash loan
    function flashLoan(
        address receiverAddress,
        address token,
        uint256 amount,
        bytes calldata params
    ) external nonReentrant {
        require(receiverAddress != address(0), "Invalid receiver");
        IERC20 asset = IERC20(token);
        uint256 balanceBefore = asset.balanceOf(address(this));
        require(balanceBefore >= amount && amount > 0, "Insufficient flash loan liquidity");

        // 1. Send borrowed tokens to the arbitrage bot contract
        asset.safeTransfer(receiverAddress, amount);

        // 2. Run the bot's arbitrage strategy (0 fee charged)
        require(
            IFlashLoanReceiver(receiverAddress).executeOperation(token, amount, 0, params),
            "Arbitrage operation failed"
        );

        // 3. Verify 100% of the borrowed amount was returned in the same transaction
        uint256 balanceAfter = asset.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan not repaid");

        emit FlashLoanExecuted(receiverAddress, token, amount);
    }
}
