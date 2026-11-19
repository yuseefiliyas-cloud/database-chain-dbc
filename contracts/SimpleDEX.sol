// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IStakingVault {
    function notifyRewardAmount(uint256 rewardAmount) external;
}

contract SimpleDEX is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable dbcToken;
    IERC20 public immutable quoteToken; // mUSDC (or USDC/WETH on mainnet)
    IStakingVault public immutable stakingVault;
    address public buybackBurnWallet;

    uint256 public reserveDBC;
    uint256 public reserveQuote;

    uint256 public constant BUY_FEE_BPS = 0;         // 0.00% fee when buying DBC
    uint256 public constant SELL_FEE_BPS = 10;       // 0.10% fee when selling DBC (10 / 10,000)
    uint256 public constant BURN_RESERVE_SHARE = 10; // 10% of collected USDC fee for DBC buyback & burn

    event LiquidityAdded(address indexed provider, uint256 dbcAmount, uint256 quoteAmount);
    event DBCBought(address indexed buyer, uint256 quoteIn, uint256 dbcOut);
    event DBCSold(address indexed seller, uint256 dbcIn, uint256 quoteOutNet, uint256 feeCollectedInQuote);

    constructor(
        address _dbcToken,
        address _quoteToken,
        address _stakingVault,
        address _buybackBurnWallet
    ) Ownable(msg.sender) {
        require(_dbcToken != address(0) && _quoteToken != address(0), "Invalid token");
        require(_stakingVault != address(0) && _buybackBurnWallet != address(0), "Invalid destination");

        dbcToken = IERC20(_dbcToken);
        quoteToken = IERC20(_quoteToken);
        stakingVault = IStakingVault(_stakingVault);
        buybackBurnWallet = _buybackBurnWallet;
    }

    // Seed or add liquidity to the DBC / mUSDC pool
    function addLiquidity(uint256 dbcAmount, uint256 quoteAmount) external nonReentrant {
        require(dbcAmount > 0 && quoteAmount > 0, "Amounts must be > 0");
        dbcToken.safeTransferFrom(msg.sender, address(this), dbcAmount);
        quoteToken.safeTransferFrom(msg.sender, address(this), quoteAmount);

        reserveDBC += dbcAmount;
        reserveQuote += quoteAmount;

        emit LiquidityAdded(msg.sender, dbcAmount, quoteAmount);
    }

    // BUY LEG: Swap mUSDC -> DBC (0.00% Fee)
    function buyDBC(uint256 quoteAmountIn, uint256 minDbcOut) external nonReentrant returns (uint256 dbcOut) {
        require(quoteAmountIn > 0, "Invalid input amount");
        require(reserveDBC > 0 && reserveQuote > 0, "Insufficient liquidity");

        quoteToken.safeTransferFrom(msg.sender, address(this), quoteAmountIn);

        // Constant product formula (x * y = k) with 0.00% fee
        dbcOut = (reserveDBC * quoteAmountIn) / (reserveQuote + quoteAmountIn);
        require(dbcOut >= minDbcOut && dbcOut < reserveDBC, "Slippage or liquidity limit");

        reserveQuote += quoteAmountIn;
        reserveDBC -= dbcOut;

        dbcToken.safeTransfer(msg.sender, dbcOut);
        emit DBCBought(msg.sender, quoteAmountIn, dbcOut);
    }

    // SELL LEG: Swap DBC -> mUSDC (0.10% Fee paid in mUSDC)
    function sellDBC(uint256 dbcAmountIn, uint256 minQuoteOut) external nonReentrant returns (uint256 netQuoteOut) {
        require(dbcAmountIn > 0, "Invalid input amount");
        require(reserveDBC > 0 && reserveQuote > 0, "Insufficient liquidity");

        dbcToken.safeTransferFrom(msg.sender, address(this), dbcAmountIn);

        // Calculate gross mUSDC output before fee
        uint256 grossQuoteOut = (reserveQuote * dbcAmountIn) / (reserveDBC + dbcAmountIn);
        require(grossQuoteOut < reserveQuote, "Insufficient quote liquidity");

        // Deduct 0.10% sell-leg fee in mUSDC
        uint256 totalFeeQuote = (grossQuoteOut * SELL_FEE_BPS) / 10_000;
        netQuoteOut = grossQuoteOut - totalFeeQuote;
        require(netQuoteOut >= minQuoteOut, "Slippage exceeded");

        // Update pool reserves
        reserveDBC += dbcAmountIn;
        reserveQuote -= grossQuoteOut;

        // Split 0.10% fee: 10% to Buyback/Burn wallet, 90% directly to StakingVault stakers
        uint256 burnShareQuote = (totalFeeQuote * BURN_RESERVE_SHARE) / 100;
        uint256 stakerShareQuote = totalFeeQuote - burnShareQuote;

        if (burnShareQuote > 0) {
            quoteToken.safeTransfer(buybackBurnWallet, burnShareQuote);
        }
        if (stakerShareQuote > 0) {
            quoteToken.safeIncreaseAllowance(address(stakingVault), stakerShareQuote);
            stakingVault.notifyRewardAmount(stakerShareQuote);
        }

        // Send net mUSDC to seller
        quoteToken.safeTransfer(msg.sender, netQuoteOut);
        emit DBCSold(msg.sender, dbcAmountIn, netQuoteOut, totalFeeQuote);
    }

    // View helper to preview how much DBC you get for buying
    function getBuyQuote(uint256 quoteAmountIn) external view returns (uint256) {
        if (reserveDBC == 0 || reserveQuote == 0) return 0;
        return (reserveDBC * quoteAmountIn) / (reserveQuote + quoteAmountIn);
    }

    // View helper to preview net mUSDC payout after 0.10% sell fee
    function getSellQuote(uint256 dbcAmountIn) external view returns (uint256 netOut, uint256 feeQuote) {
        if (reserveDBC == 0 || reserveQuote == 0) return (0, 0);
        uint256 grossOut = (reserveQuote * dbcAmountIn) / (reserveDBC + dbcAmountIn);
        feeQuote = (grossOut * SELL_FEE_BPS) / 10_000;
        netOut = grossOut - feeQuote;
    }
}
