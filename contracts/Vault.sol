// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {

    struct StakeInfo {
        uint256 amount;
        uint256 index;
    }

    IERC20 public token;
    mapping(address => StakeInfo) public stakeInfo;
    address[] public stakers;

    event Deposit(address indexed, uint256 indexed);
    event Withdraw(address indexed, uint256 indexed);

    constructor(address _token) {
        require(_token != address(0), "Err:IT"); //IT: Invalid token address
        token = IERC20(_token);
    }

    /**
     * @dev Deposit specific amount of token into the pool.
     * @param amount The amount of staking token to deposit
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Err:IA"); // IA: Invalid amount
        token.transferFrom(msg.sender, address(this), amount);
        StakeInfo memory staker = stakeInfo[msg.sender];
        if (staker.amount == 0) {
            staker.index = stakers.length;
            stakers.push(msg.sender);
        }
        staker.amount += amount;
        stakeInfo[msg.sender] = staker;
        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev Withdraw staked token from the pool.
     * @param amount The amount of staking token to withdraw
     */
    function withdraw(uint256 amount) external {
        require(stakeInfo[msg.sender].amount >= amount, "Err:IA"); // IA: Invalid amount
        stakeInfo[msg.sender].amount -= amount;
        if (stakeInfo[msg.sender].amount == 0) {
            uint256 index = stakeInfo[msg.sender].index;
            address lastStaker = stakers[stakers.length - 1];
            stakeInfo[lastStaker].index = index;
            stakeInfo[msg.sender].index = 0;
            stakers[index] = lastStaker;
            stakers.pop();
        }
        token.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev Returns 2 users with most of funds in the pool
     * @return address[2] Returns an array of user addresses
     */
    function getTopStakers() external view returns (address[2] memory) {
        address[2] memory whales;
        uint256 totalCnt = stakers.length;
        for (uint256 i = 0; i < totalCnt; i++) {
            address staker = stakers[i];
            if (stakeInfo[staker].amount > stakeInfo[whales[0]].amount) {
                whales[1] = whales[0];
                whales[0] = staker;
            }
            else if (stakeInfo[staker].amount > stakeInfo[whales[1]].amount) {
                whales[1] = staker;
            }
        }
        return whales;
    }

    /**
     * @dev Set the token address to be staked. Only owner can do this.
     * @param _token Token address to be set
     */
    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "Err:IT"); //IT: Invalid token address
        token = IERC20(_token);
    }

    /**
     * @dev Claims staked token from the pool manually. This is in case of emergency. Only owner can do this.
     * @param _token Address of staked token
     * @param _to Address of a wallet where the token will be sent to.
     * @param _amount Amount of token to be claimed
     */
    function claimToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }
}