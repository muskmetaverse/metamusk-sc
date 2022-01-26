// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../interfaces/IERC20UpgradeableMetaMusk.sol";
import "../libs/SafeERC20UpgradeableMetaMusk.sol";

contract MetaMuskICO is Initializable, ContextUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public tokenBUSD;

    using SafeERC20UpgradeableMetaMusk for IERC20UpgradeableMetaMusk;
    IERC20UpgradeableMetaMusk public tokenMetaMusk;

    uint256 public startTimeICO;
    uint256 public endTimeICO;
    uint256 public totalAmountPerBUSD;

    AggregatorV3Interface internal priceFeed;
    address public priceFeedAddress;

    function initialize(
        uint256 _startTimeICO,
        uint256 _endTimeICO,
        uint256 _totalAmountPerBUSD,
        address _busdContractAddress,
        address _metamuskContractAddress,
        address _priceFeedAddress
    ) public initializer {
        require(_startTimeICO < _endTimeICO, "invalid ICO time");
        require(_totalAmountPerBUSD > 0, "invalid rate buy ICO by BUSD");
        require(
            _busdContractAddress != address(0),
            "invalid busd contract address"
        );
        require(
            _metamuskContractAddress != address(0),
            "invalid MetaMusk contract address"
        );
        require(_priceFeedAddress != address(0), "invalid operator address");

        startTimeICO = _startTimeICO;
        endTimeICO = _endTimeICO;
        totalAmountPerBUSD = _totalAmountPerBUSD;

        tokenBUSD = IERC20Upgradeable(_busdContractAddress);
        tokenMetaMusk = IERC20UpgradeableMetaMusk(_metamuskContractAddress);

        priceFeedAddress = _priceFeedAddress;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);

        __Ownable_init();
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function buyICOByBUSD(uint256 amount) external payable {
        _precheckBuy(amount);

        uint256 buyAmountToken = amount * totalAmountPerBUSD;
        _precheckContractAmount(buyAmountToken);

        address sender = _msgSender();
        tokenBUSD.safeTransferFrom(sender, address(this), amount);
        tokenMetaMusk.transferLockToken(sender, buyAmountToken);
    }

    function buyICO() external payable {
        _precheckBuy(msg.value);

        int256 busdBNBPrice = this.getLatestPrice();
        uint256 totalBUSDConverted = (msg.value * (10**18)) /
            uint256(busdBNBPrice);
        uint256 buyAmountToken = totalBUSDConverted.mul(totalAmountPerBUSD);
        _precheckContractAmount(buyAmountToken);

        address sender = _msgSender();
        tokenMetaMusk.transferLockToken(sender, buyAmountToken);
    }

    function setPriceFeedAddress(address _priceFeedAddress) external onlyOwner {
        require(priceFeedAddress != address(0), "Cannot be zero address");
        priceFeedAddress = _priceFeedAddress;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function claimBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function claimBUSD() external onlyOwner {
        uint256 remainAmountToken = tokenBUSD.balanceOf(address(this));
        tokenBUSD.transfer(msg.sender, remainAmountToken);
    }

    function claimToken() external onlyOwner {
        address sender = _msgSender();
        uint256 remainAmountToken = tokenMetaMusk.balanceOf(address(this));
        tokenMetaMusk.safeTransfer(sender, remainAmountToken);
    }

    function setRoundInfo(
        uint256 _startTimeICO,
        uint256 _endTimeICO,
        uint256 _totalAmountPerBUSD
    ) external onlyOwner {
        require(_startTimeICO < _endTimeICO, "invalid time");
        require(_totalAmountPerBUSD > 0, "invalid rate buy ICO by BUSD");

        startTimeICO = _startTimeICO;
        endTimeICO = _endTimeICO;
        totalAmountPerBUSD = _totalAmountPerBUSD;
    }

    function _precheckBuy(uint256 amount) internal view {
        require(amount > 0, "value must be greater than 0");
        require(block.timestamp >= startTimeICO, "ICO time dose not start now");
        require(block.timestamp <= endTimeICO, "ICO time is expired");
    }

    function _precheckContractAmount(uint256 transferAmount) internal view {
        uint256 remainAmountToken = tokenMetaMusk.balanceOf(address(this));
        require(
            transferAmount <= remainAmountToken,
            "The contract does not enough amount token to buy"
        );
    }
}
