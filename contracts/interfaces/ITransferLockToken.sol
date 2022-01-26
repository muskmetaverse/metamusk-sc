// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ITransferLockToken {
    function transferLockToken(address recipient, uint256 amount)
        external
        returns (bool);
}
