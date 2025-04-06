// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";

contract RestaurantVoucherNFT is ERC1155, Ownable, ERC1155Pausable {
    // Definindo erros customizados
    error EmptyName();
    error EmptyURI();
    error InvalidPrice();
    error InvalidSupply();
    error InvalidSalePeriod();
    error UseByBeforeSaleEnd();
    error MaxVouchersReached();
    error NotVoucherOwner();
    error InsufficientVouchers();
    error VoucherExpired();
    error VoucherInactive();
    error ExceedsMaxSupply();
    error ArraysLengthMismatch();
    error EmptyArrays();
    error BatchTooLarge();

    uint256 public constant MAX_VOUCHERS_PER_RESTAURANT = 100;
    uint256 public constant MAX_BATCH_SIZE = 100;
    string contractVoucherURI; // URI padrão para o contrato
    string public name;
    string public symbol;

    struct VoucherInfo {
        address restaurant;
        uint256 price;
        uint256 maxSupply;
        uint256 currentSupply;
        uint256 saleStart;
        uint256 saleEnd;
        uint256 useBy;
        bool isActive;
        string dishName;
        string uri;
    }

    mapping(uint256 => VoucherInfo) public voucherInfo;
    mapping(address => uint256[]) public restaurantVouchers;
    mapping(address => mapping(uint256 => uint256)) public restaurantVoucherIndex;

    event VoucherCreated(
        uint256 indexed id,
        address indexed restaurant,
        string dishName,
        uint256 price,
        uint256 maxSupply,
        uint256 saleStart,
        uint256 saleEnd,
        uint256 useBy,
        string uri
    );

    event VoucherRedeemed(uint256 indexed id, address indexed customer, address indexed restaurant, uint256 amount);

    event VoucherStatusChanged(uint256 indexed id, bool isActive);

    constructor(address initialOwner, string memory nameRV, string memory symbolRV, string memory uriContract)
        ERC1155("")
        Ownable(initialOwner)
    {
        name = nameRV;
        symbol = symbolRV;
        contractVoucherURI = uriContract;
    }

    function createVoucher(
        string memory dishName,
        uint256 voucherId,
        uint256 price,
        uint256 maxSupply,
        uint256 saleStart,
        uint256 saleEnd,
        uint256 useBy,
        string memory uriVoucher
    ) external whenNotPaused onlyOwner {
        if (bytes(dishName).length == 0) revert EmptyName();
        if (bytes(uriVoucher).length == 0) revert EmptyURI();
        if (price == 0) revert InvalidPrice();
        if (maxSupply == 0) revert InvalidSupply();
        if (saleStart >= saleEnd) revert InvalidSalePeriod();
        if (saleEnd >= useBy) revert UseByBeforeSaleEnd();
        if (restaurantVouchers[msg.sender].length >= MAX_VOUCHERS_PER_RESTAURANT) revert MaxVouchersReached();
        if (voucherInfo[voucherId].restaurant != address(0)) revert NotVoucherOwner();

        voucherInfo[voucherId] = VoucherInfo({
            restaurant: msg.sender,
            price: price,
            maxSupply: maxSupply,
            currentSupply: 0,
            saleStart: saleStart,
            saleEnd: saleEnd,
            useBy: useBy,
            isActive: true,
            dishName: dishName,
            uri: uriVoucher
        });

        restaurantVouchers[msg.sender].push(voucherId);
        restaurantVoucherIndex[msg.sender][voucherId] = restaurantVouchers[msg.sender].length;

        emit VoucherCreated(voucherId, msg.sender, dishName, price, maxSupply, saleStart, saleEnd, useBy, uriVoucher);
    }

    function mintVoucher(address to, uint256 id, uint256 amount) external whenNotPaused onlyOwner {
        if ((voucherInfo[id].currentSupply + amount) > voucherInfo[id].maxSupply) revert ExceedsMaxSupply();
        voucherInfo[id].currentSupply = voucherInfo[id].currentSupply + amount;
        _mint(to, id, amount, "");
    }

    function redeemVoucher(uint256 id, uint256 amount) external {
        if (balanceOf(msg.sender, id) < amount) revert InsufficientVouchers();
        if (block.timestamp > voucherInfo[id].useBy) revert VoucherExpired();
        if (!voucherInfo[id].isActive) revert VoucherInactive();

        _burn(msg.sender, id, amount);
        emit VoucherRedeemed(id, msg.sender, voucherInfo[id].restaurant, amount);
    }

    function batchMintVouchers(address to, uint256[] memory ids, uint256[] memory amounts)
        external
        whenNotPaused
        onlyOwner
    {
        if (ids.length != amounts.length) revert ArraysLengthMismatch();
        if (ids.length == 0) revert EmptyArrays();
        if (ids.length > MAX_BATCH_SIZE) revert BatchTooLarge();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (voucherInfo[id].restaurant != msg.sender) revert NotVoucherOwner();
            if ((voucherInfo[id].currentSupply + amount) > voucherInfo[id].maxSupply) revert ExceedsMaxSupply();

            voucherInfo[id].currentSupply = voucherInfo[id].currentSupply + amount;
        }

        _mintBatch(to, ids, amounts, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return voucherInfo[id].uri;
    }

    function getVoucherInfo(uint256 id) external view returns (VoucherInfo memory) {
        return voucherInfo[id];
    }

    function getVouchersByRestaurant(address restaurant) external view returns (uint256[] memory) {
        return restaurantVouchers[restaurant];
    }

    function setVoucherActive(uint256 id, bool isActive) external {
        if (voucherInfo[id].restaurant != msg.sender) revert NotVoucherOwner();
        voucherInfo[id].isActive = isActive;
        emit VoucherStatusChanged(id, isActive);
    }

    function contractURI() public view returns (string memory) {
        return contractVoucherURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable)
    {
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return interfaceId == type(IERC1155MetadataURI).interfaceId || super.supportsInterface(interfaceId);
    }
}
