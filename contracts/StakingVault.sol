// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StakingVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable dbcToken;
    IERC20 public immutable rewardToken; // mUSDC (or USDC/WETH on mainnet)

    uint256 public totalStaked;
    uint256 public accRewardPerShare;
    uint256 private constant PRECISION = 1e18;

    mapping(address => uint256) public userStaked;
    mapping(address => uint256) public userRewardDebt;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _dbcToken, address _rewardToken) {
        require(_dbcToken != address(0) && _rewardToken != address(0), "Invalid token");
        dbcToken = IERC20(_dbcToken);
        rewardToken = IERC20(_rewardToken);
    }

    // Called when SimpleDEX sends 90% of sell-leg USDC fees to this vault
    function notifyRewardAmount(uint256 rewardAmount) external nonReentrant {
        require(rewardAmount > 0, "Reward must be > 0");
        rewardToken.safeTransferFrom(msg.sender, address(this), rewardAmount);

        if (totalStaked > 0) {
            accRewardPerShare += (rewardAmount * PRECISION) / totalStaked;
        }
        emit RewardsDistributed(rewardAmount);
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        _claim(msg.sender);

        dbcToken.safeTransferFrom(msg.sender, address(this), amount);
        userStaked[msg.sender] += amount;
        totalStaked += amount;
        userRewardDebt[msg.sender] = (userStaked[msg.sender] * accRewardPerShare) / PRECISION;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0 && userStaked[msg.sender] >= amount, "Invalid unstake amount");
        _claim(msg.sender);

        userStaked[msg.sender] -= amount;
        totalStaked -= amount;
        userRewardDebt[msg.sender] = (userStaked[msg.sender] * accRewardPerShare) / PRECISION;

        dbcToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external nonReentrant {
        _claim(msg.sender);
        userRewardDebt[msg.sender] = (userStaked[msg.sender] * accRewardPerShare) / PRECISION;
    }

    function pendingRewards(address user) external view returns (uint256) {
        return ((userStaked[user] * accRewardPerShare) / PRECISION) - userRewardDebt[user];
    }

    function _claim(address user) internal {
        if (userStaked[user] > 0) {
            uint256 pending = ((userStaked[user] * accRewardPerShare) / PRECISION) - userRewardDebt[user];
            if (pending > 0) {
                rewardToken.safeTransfer(user, pending);
                emit RewardClaimed(user, pending);
            }
        }
    }
}
