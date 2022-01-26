// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../interfaces/IERC20UpgradeableMetaMusk.sol";
import "../libs/SafeERC20UpgradeableMetaMusk.sol";

contract MetaMuskAirdrop is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    using SafeERC20UpgradeableMetaMusk for IERC20UpgradeableMetaMusk;
    IERC20UpgradeableMetaMusk public tokenMetaMusk;

    struct Airdrop {
        address userAddress;
        uint256 amount;
    }
    address public operatorAddress;

    function initialize(
        address _metamuskContractAddress,
        address _operatorAddress
    ) public initializer {
        require(
            _metamuskContractAddress != address(0),
            "invalid MetaMusk contract address"
        );
        require(_operatorAddress != address(0), "invalid operator address");

        operatorAddress = _operatorAddress;
        tokenMetaMusk = IERC20UpgradeableMetaMusk(_metamuskContractAddress);

        __Ownable_init();
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Your are not operator");
        _;
    }

    function transferAirdrops(Airdrop[] memory arrAirdrop, uint256 totalAmount)
        external
        onlyOperator
    {
        _precheckContractAmount(totalAmount);
        for (uint256 i = 0; i < arrAirdrop.length; i++) {
            _transferAirdrop(arrAirdrop[i].userAddress, arrAirdrop[i].amount);
        }
    }

    function setOperator(address _operatorAddress) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
    }

    function claimBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function claimToken() external onlyOwner {
        address sender = _msgSender();
        uint256 remainAmountToken = tokenMetaMusk.balanceOf(address(this));
        tokenMetaMusk.safeTransfer(sender, remainAmountToken);
    }

    function _precheckContractAmount(uint256 transferAmount) internal view {
        uint256 remainAmountToken = tokenMetaMusk.balanceOf(address(this));
        require(
            transferAmount <= remainAmountToken,
            "The contract does not enough amount token to buy"
        );
    }

    function _transferAirdrop(address toAddress, uint256 amount) internal {
        tokenMetaMusk.transferLockToken(toAddress, amount);
    }
}
