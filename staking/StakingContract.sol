// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IHubXToken
 * @dev Interface for the HUBX token to allow the staking contract to interact with it.
 */
interface IHubXToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title StakingContract
 * @dev Implementation of the staking mechanism for the HUBX protocol.
 * Users can stake HUBX tokens to earn rewards over time.
 */
contract StakingContract {
    IHubXToken public immutable hubxToken;

    // Reward rate per second (e.g., 0.000001 HUBX per staked HUBX per second)
    // For simplicity, we'll use a fixed rate. In production, this could be dynamic.
    uint256 public constant REWARD_RATE = 100; // 100 units per staked token per day (scaled)
    uint256 public constant SCALE = 1e18;
    uint256 public constant SECONDS_IN_DAY = 86400;

    struct StakeInfo {
        uint256 amount;
        uint256 lastUpdateTimestamp;
        uint256 pendingRewards;
    }

    mapping(address => StakeInfo) public userStakes;
    uint256 public totalStaked;

    // Reentrancy guard
    bool private _locked;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);

    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    /**
     * @dev Constructor to set the HUBX token address.
     * @param _hubxToken Address of the HUBX token contract.
     */
    constructor(address _hubxToken) {
        require(_hubxToken != address(0), "Invalid token address");
        hubxToken = IHubXToken(_hubxToken);
    }

    /**
     * @dev Internal function to calculate and update pending rewards for a user.
     * @param user The address of the user.
     */
    function _updateRewards(address user) internal {
        StakeInfo storage stakeInfo = userStakes[user];
        if (stakeInfo.amount > 0) {
            uint256 duration = block.timestamp - stakeInfo.lastUpdateTimestamp;
            // reward = amount * rate * duration / seconds_in_day
            uint256 reward = (stakeInfo.amount * REWARD_RATE * duration) / SECONDS_IN_DAY;
            stakeInfo.pendingRewards += reward;
        }
        stakeInfo.lastUpdateTimestamp = block.timestamp;
    }

    /**
     * @dev Stakes HUBX tokens.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        
        _updateRewards(msg.sender);

        require(hubxToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        userStakes[msg.sender].amount += amount;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Calculates the current pending rewards for a user.
     * @param user The address of the user.
     * @return The amount of pending rewards.
     */
    function calculateReward(address user) public view returns (uint256) {
        StakeInfo memory stakeInfo = userStakes[user];
        uint256 reward = stakeInfo.pendingRewards;
        
        if (stakeInfo.amount > 0) {
            uint256 duration = block.timestamp - stakeInfo.lastUpdateTimestamp;
            reward += (stakeInfo.amount * REWARD_RATE * duration) / SECONDS_IN_DAY;
        }
        
        return reward;
    }

    /**
     * @dev Claims pending rewards.
     */
    function claimRewards() external nonReentrant {
        _updateRewards(msg.sender);
        
        uint256 reward = userStakes[msg.sender].pendingRewards;
        require(reward > 0, "No rewards to claim");

        userStakes[msg.sender].pendingRewards = 0;
        
        require(hubxToken.transfer(msg.sender, reward), "Reward transfer failed");

        emit RewardsClaimed(msg.sender, reward);
    }

    /**
     * @dev Withdraws staked HUBX tokens.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) external nonReentrant {
        StakeInfo storage stakeInfo = userStakes[msg.sender];
        require(amount > 0, "Cannot withdraw 0");
        require(stakeInfo.amount >= amount, "Insufficient staked balance");

        _updateRewards(msg.sender);

        stakeInfo.amount -= amount;
        totalStaked -= amount;

        require(hubxToken.transfer(msg.sender, amount), "Withdrawal transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Returns the staked amount for a user.
     * @param user The address of the user.
     * @return The amount of tokens staked.
     */
    function getStakedAmount(address user) external view returns (uint256) {
        return userStakes[user].amount;
    }
}
