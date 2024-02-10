// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "src/MultiSigWallet.sol";

contract TestContract is Test {

    event Deposit(address indexed sender, uint256 amount, uint256 balance);


    MultiSigWallet wallet;
    address public constant HOLDER_1 = payable(address(1));
    address public constant HOLDER_2 = payable(address(2));
    address public constant HOLDER_3 = payable(address(3));
    address public constant HACKER = payable(address(4));
    address[] public HOLDERS = [HOLDER_1, HOLDER_2, HOLDER_3];
    address[] public HOLDERS_WITH_ZERO = [HOLDER_1, HOLDER_2, address(0)];
    address[] public HOLDERS_WITH_DUP = [HOLDER_1, HOLDER_2, HOLDER_2];
    uint256 public constant TEST_ETHER = 5 ether;
    uint256 public REQUIRED_CONFIRMS = HOLDERS.length - 1;

    function setUp() public {
        wallet = new MultiSigWallet(HOLDERS, REQUIRED_CONFIRMS);
    }

    function testRevertEmptyOwners() public {
        vm.expectRevert(EmptyOwners.selector);
        wallet = new MultiSigWallet(new address[](0), REQUIRED_CONFIRMS);
    }

    function testRevertInvalidRequiredConfirms() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidRequiredConfirms.selector, 0, 3));
        wallet = new MultiSigWallet(HOLDERS, 0);
        vm.expectRevert(abi.encodeWithSelector(InvalidRequiredConfirms.selector, REQUIRED_CONFIRMS + 2, 3));
        wallet = new MultiSigWallet(HOLDERS, REQUIRED_CONFIRMS + 2);
    }

    function testRevertZeroAddressOwner() public {
        vm.expectRevert(ZeroAddressOwner.selector);
        wallet = wallet = new MultiSigWallet(HOLDERS_WITH_ZERO, REQUIRED_CONFIRMS);
    }
    
    function testRevertDuplicateOwner() public {
        vm.expectRevert(DuplicateOwner.selector);
        wallet = wallet = new MultiSigWallet(HOLDERS_WITH_DUP, REQUIRED_CONFIRMS);
    }

    function testDefaultContractConstruct() public {
        assertEq(wallet.getOwners().length, HOLDERS.length);
        assertEq(wallet.numConfirmationsRequired(), REQUIRED_CONFIRMS);
    }

    function testSendEtherWithoutData() public {
        vm.deal(HOLDER_1, TEST_ETHER + 1 ether);
        vm.startPrank(HOLDER_1);
        vm.expectEmit(address(wallet));
        emit Deposit(HOLDER_1, TEST_ETHER, TEST_ETHER);
        (bool sent, ) = address(wallet).call{value: TEST_ETHER}("");
        require(sent, "Failed to send Ether");
        vm.stopPrank();
        assertEq(address(wallet).balance, TEST_ETHER);
        assertEq(HOLDER_1.balance, 1 ether);
    }

    function testRevertSendEtherWithData() public {
        vm.deal(HOLDER_1, TEST_ETHER);
        vm.startPrank(HOLDER_1);
        bytes memory testCall = abi.encodeCall(MultiSigWallet.getOwners, ());
        vm.expectRevert();
        (bool sent, bytes memory res) = address(wallet).call{value: TEST_ETHER}(testCall);
        vm.stopPrank();
        assertEq(sent, true);
        assertEq(res, new bytes(8192));
        assertEq(address(wallet).balance, 0);
        assertEq(HOLDER_1.balance, TEST_ETHER);
    }
}
