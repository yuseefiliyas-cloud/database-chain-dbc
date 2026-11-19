// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FounderVesting {
    using SafeERC20 for IERC20;

    IERC20 public immutable dbcToken;
    address public immutable beneficiary;
    uint256 public immutable startTimestamp;
    uint256 public immutable cliffDuration = 180 days;    // 6-month lock
    uint256 public immutable vestingDuration = 730 days;  // 24-month linear unlock
    uint256 public released;

    constructor(address _dbcToken, address _beneficiary) {
        require(_dbcToken != address(0) && _beneficiary != address(0), "Invalid address");
        dbcToken = IERC20(_dbcToken);
        beneficiary = _beneficiary;
        startTimestamp = block.timestamp;
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < startTimestamp + cliffDuration) {
            return 0;
        }
        uint256 totalBalance = dbcToken.balanceOf(address(this)) + released;
        uint256 elapsed = block.timestamp - (startTimestamp + cliffDuration);

        if (elapsed >= vestingDuration) {
            return totalBalance - released;
        }
        uint256 vested = (totalBalance * elapsed) / vestingDuration;
        return vested - released;
    }

    function release() external {
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens unlocked yet");
        released += amount;
        dbcToken.safeTransfer(beneficiary, amount);
    }
}

