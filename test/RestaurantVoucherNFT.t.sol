// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/RestaurantVoucherNFT.sol";

contract RestaurantVoucherNFTEdgeCasesTest is Test {
    RestaurantVoucherNFT public voucherNFT;
    address public owner = address(0x1);
    address public restaurant = address(0x2);

    function setUp() public {
        vm.prank(owner);
        voucherNFT = new RestaurantVoucherNFT(owner, "Restaurant Vouchers", "RVO", "https://example.com/api/v1/");
    }

    // Test max vouchers per restaurant
    function testMaxVouchersPerRestaurant() public {
        for (uint256 i = 1; i <= 100; i++) {
            vm.prank(owner);
            voucherNFT.createVoucher(
                string(abi.encodePacked("Dish ", i)),
                i,
                0.1 ether,
                10,
                uint64(block.timestamp),
                uint64(block.timestamp + 7 days),
                uint64(block.timestamp + 14 days),
                string(abi.encodePacked("https://example.com/", i))
            );
        }

        vm.prank(owner);
        vm.expectRevert(RestaurantVoucherNFT.MaxVouchersReached.selector);
        voucherNFT.createVoucher(
            "Extra Dish",
            101,
            0.1 ether,
            10,
            uint64(block.timestamp),
            uint64(block.timestamp + 7 days),
            uint64(block.timestamp + 14 days),
            "https://example.com/extra"
        );
    }

    // Test batch mint edge cases
    function testBatchMintEdgeCases() public {
        uint256[] memory ids = new uint256[](3);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 5;
        amounts[1] = 10;
        amounts[2] = 15;

        // Create vouchers
        for (uint256 i = 0; i < ids.length; i++) {
            vm.prank(owner);
            voucherNFT.createVoucher(
                string(abi.encodePacked("Dish ", ids[i])),
                ids[i],
                0.1 ether,
                100,
                uint64(block.timestamp),
                uint64(block.timestamp + 7 days),
                uint64(block.timestamp + 14 days),
                string(abi.encodePacked("https://example.com/", ids[i]))
            );
        }

        // Test empty arrays
        vm.prank(owner);
        vm.expectRevert(RestaurantVoucherNFT.EmptyArrays.selector);
        voucherNFT.batchMintVouchers(address(0x4), new uint256[](0), new uint256[](0));

        // Test array length mismatch
        vm.prank(owner);
        vm.expectRevert(RestaurantVoucherNFT.ArraysLengthMismatch.selector);
        voucherNFT.batchMintVouchers(address(0x4), ids, new uint256[](2));

        // Test batch too large
        uint256[] memory largeIds = new uint256[](101);
        uint256[] memory largeAmounts = new uint256[](101);

        vm.prank(owner);
        vm.expectRevert(RestaurantVoucherNFT.BatchTooLarge.selector);
        voucherNFT.batchMintVouchers(address(0x4), largeIds, largeAmounts);
    }

    // Test voucher status changes
    function testVoucherStatusChanges() public {
        uint256 voucherId = 1;
        vm.prank(owner);
        voucherNFT.createVoucher(
            "Bife",
            voucherId,
            0.1 ether,
            100,
            uint64(block.timestamp),
            uint64(block.timestamp + 7 days),
            uint64(block.timestamp + 14 days),
            "https://example.com/bife"
        );

        // Test setting inactive
        vm.prank(owner);
        voucherNFT.setVoucherActive(voucherId, false);
        assertEq(voucherNFT.getVoucherInfo(voucherId).isActive, false);

        // Test cannot redeem inactive
        vm.prank(owner);
        voucherNFT.mintVoucher(address(0x4), voucherId, 1);

        vm.prank(address(0x4));
        vm.expectRevert(RestaurantVoucherNFT.VoucherInactive.selector);
        voucherNFT.redeemVoucher(voucherId, 1);

        // Test setting back to active
        vm.prank(owner);
        voucherNFT.setVoucherActive(voucherId, true);
        assertEq(voucherNFT.getVoucherInfo(voucherId).isActive, true);
    }

    // Test interface support
    function testSupportsInterface() public view {
        // ERC1155 interface
        assertTrue(voucherNFT.supportsInterface(0xd9b67a26));
        // ERC1155MetadataURI interface
        assertTrue(voucherNFT.supportsInterface(0x0e89341c));
        // Invalid interface
        assertFalse(voucherNFT.supportsInterface(0xffffffff));
    }
}
