// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "src/MultiSigWallet.sol";

contract TestContract is Test {
    MultiSigWallet wallet;
    address public constant HOLDER_1 = payable(address(1));
    address public constant HOLDER_2 = payable(address(2));
    address public constant HOLDER_3 = payable(address(3));
    address public constant HACKER = payable(address(4));
    address[] public HOLDERS = [HOLDER_1, HOLDER_2, HOLDER_3];
    uint256 public constant TEST_ETHER = 5 ether;
    uint256 public REQUIRED_CONFIRMS = HOLDERS.length - 1;

    function setUp() public {
        wallet = new MultiSigWallet(HOLDERS, REQUIRED_CONFIRMS);
    }

    function testContractConstruct() public {
        assertEq(wallet.getOwners().length, HOLDERS.length);
        assertEq(wallet.numConfirmationsRequired(), REQUIRED_CONFIRMS);
    }
}
