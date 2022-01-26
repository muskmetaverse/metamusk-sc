// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MetaMuskToken is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public tokenBUSD;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;

    uint256 public startTimeICO;
    uint256 public endTimeICO;
    uint256 public totalAmountPerBUSD;
    uint256 public percentClaimPerDate;
    mapping(address => UserInfo) public users;
    struct UserInfo {
        uint256 amountICO;
        uint256 amountClaimPerSec;
        uint256 claimAt;
        bool isSetup;
    }

    address public operatorAddress;
    struct Airdrop {
        address userAddress;
        uint256 amount;
    }

    AggregatorV3Interface internal priceFeed;
    address priceFeedAddress;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_)
        internal
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_)
        internal
        initializer
    {
        _name = name_;
        _symbol = symbol_;
    }

    function initialize(
        uint256 _startTimeICO,
        uint256 _endTimeICO,
        uint256 _totalAmountPerBUSD,
        uint256 _percentClaimPerDate,
        address _busdContractAddress,
        address _operatorAddress,
        address _priceFeedAddress
    ) public initializer {
        require(_startTimeICO < _endTimeICO, "invalid ICO time");
        require(_totalAmountPerBUSD > 0, "invalid rate buy ICO by BUSD");
        require(_percentClaimPerDate > 0, "invalid unlock percent per day");
        require(
            _busdContractAddress != address(0),
            "invalid busd contract address"
        );

        startTimeICO = _startTimeICO;
        endTimeICO = _endTimeICO;
        totalAmountPerBUSD = _totalAmountPerBUSD;
        percentClaimPerDate = _percentClaimPerDate;
        tokenBUSD = IERC20Upgradeable(_busdContractAddress);
        operatorAddress = _operatorAddress;

        priceFeedAddress = _priceFeedAddress;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);

        _name = "METAMUSK";
        _symbol = "METAMUSK";
        _decimals = 18;

        __ERC20_init(_name, _symbol);
        __Ownable_init();
        uint256 totalAmount = 1000000000000000 * 10**_decimals;
        _mint(msg.sender, totalAmount);

        emit Transfer(address(0), msg.sender, totalAmount);
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Your are not operator");
        _;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view virtual returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
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
        uint256 buyAmountToken = amount * totalAmountPerBUSD;
        _precheckBuy(amount, buyAmountToken);

        address sender = _msgSender();
        tokenBUSD.safeTransferFrom(sender, address(this), amount);
        _buy(sender, buyAmountToken);
    }

    function buyICO() external payable {
        int256 busdBNBPrice = this.getLatestPrice();
        uint256 totalBUSDConverted = (msg.value * (10**_decimals)) /
            uint256(busdBNBPrice);
        uint256 buyAmountToken = totalBUSDConverted.mul(totalAmountPerBUSD);
        _precheckBuy(msg.value, buyAmountToken);

        address sender = _msgSender();
        _buy(sender, buyAmountToken);
    }

    function transferAirdrops(Airdrop[] memory arrAirdrop, uint256 totalAmount)
        external
        onlyOperator
    {
        _precheckAirdrop(totalAmount);
        for (uint256 i = 0; i < arrAirdrop.length; i++) {
            _transferAirdrop(arrAirdrop[i].userAddress, arrAirdrop[i].amount);
        }
    }

    /**
     * @dev set operator address
     * callable by owner
     */
    function setOperator(address _operatorAddress) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function getAvailableBalance() external view returns (uint256) {
        address sender = _msgSender();

        uint256 availableAmount = _balances[sender] - users[sender].amountICO;
        if (users[sender].isSetup == true && users[sender].amountICO > 0) {
            uint256 unlockAmount = _getUnlockAmount(sender);
            availableAmount = availableAmount.add(unlockAmount);
        }

        return availableAmount;
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
        uint256 remainAmountToken = this.balanceOf(address(this));
        this.transfer(sender, remainAmountToken);
    }

    function setRoundInfo(
        uint256 _startTimeICO,
        uint256 _endTimeICO,
        uint256 _totalAmountPerBUSD,
        uint256 _percentClaimPerDate
    ) external onlyOwner {
        require(_startTimeICO < _endTimeICO, "invalid time");
        require(_totalAmountPerBUSD > 0, "invalid rate buy ICO by BUSD");
        require(_percentClaimPerDate > 0, "invalid unlock percent per day");

        startTimeICO = _startTimeICO;
        endTimeICO = _endTimeICO;
        totalAmountPerBUSD = _totalAmountPerBUSD;
        percentClaimPerDate = _percentClaimPerDate;
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        uint256 availableAmount = _balances[sender].sub(
            users[sender].amountICO
        );
        uint256 unlockAmount = 0;
        if (
            users[sender].isSetup == true &&
            users[sender].amountICO > 0 &&
            availableAmount < amount
        ) {
            unlockAmount = _getUnlockAmount(sender);
            availableAmount = availableAmount.add(unlockAmount);
            require(
                availableAmount >= amount,
                "some available balance has been locked and will be unlocked gradually"
            );
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);

        if (unlockAmount > 0) {
            users[sender].amountICO = users[sender].amountICO.sub(unlockAmount);
            users[sender].amountICO = users[sender].amountICO < 0
                ? 0
                : users[sender].amountICO;
            users[sender].claimAt = block.timestamp;
        }

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }

    function _calTotalAmountPerSec(uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 numOfDays = (100 * 100) / percentClaimPerDate;
        uint256 totalSeconds = numOfDays * 24 * 60 * 60;
        uint256 totalAmountPerSec = amount / totalSeconds;
        return totalAmountPerSec;
    }

    function _getUnlockAmount(address account) internal view returns (uint256) {
        if (users[account].isSetup == false || users[account].amountICO == 0)
            return 0;

        uint256 diff = block.timestamp - users[account].claimAt;
        uint256 claimAmount = users[account].amountClaimPerSec * diff;

        if (claimAmount > users[account].amountICO)
            claimAmount = users[account].amountICO;

        return claimAmount;
    }

    function _precheckBuy(uint256 amount, uint256 buyAmountToken)
        internal
        view
    {
        require(amount > 0, "value must be greater than 0");
        require(block.timestamp >= startTimeICO, "ICO time dose not start now");
        require(block.timestamp <= endTimeICO, "ICO time is expired");

        uint256 remainAmountToken = this.balanceOf(address(this));
        require(
            buyAmountToken <= remainAmountToken,
            "The contract does not enough amount token to buy"
        );
    }

    function _transferAirdrop(address toAddress, uint256 amount) internal {
        _precheckAirdrop(amount);
        _buy(toAddress, amount);
    }

    function _precheckAirdrop(uint256 amount) internal view {
        uint256 remainAmountToken = this.balanceOf(address(this));
        require(
            amount <= remainAmountToken,
            "The contract does not enough amount token to airdrop"
        );
    }

    function _buy(address sender, uint256 buyAmountToken) internal {
        if (users[sender].isSetup == false) {
            UserInfo storage userInfo = users[sender];
            userInfo.amountICO = buyAmountToken;
            userInfo.amountClaimPerSec = _calTotalAmountPerSec(buyAmountToken);
            users[sender].claimAt = block.timestamp;
            userInfo.isSetup = true;
        } else {
            users[sender].amountICO += buyAmountToken;
            users[sender].amountClaimPerSec = _calTotalAmountPerSec(
                users[sender].amountICO
            );
        }

        _transfer(address(this), sender, buyAmountToken);
    }
}
