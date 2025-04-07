// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
/// @title RestaurantVoucherNFT - Contrato de Vouchers Sazonais para Restaurantes
/// @notice Contrato ERC-1155 para gerenciamento de vouchers de restaurantes com funcionalidades avançadas
/// @dev Implementa ERC1155 com extensões Pausable e proteção contra reentrância

contract RestaurantVoucherNFT is ERC1155, Ownable, ERC1155Pausable, ReentrancyGuard {
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

    /// @notice Estrutura de dados para informações do voucher
    /// @dev Otimizada para packing de armazenamento
    struct VoucherInfo {
        address restaurant;
        uint64 saleStart;
        uint64 saleEnd;
        uint64 useBy;
        uint256 price;
        uint256 maxSupply;
        uint256 currentSupply;
        bool isActive;
        string dishName;
        string uri;
    }

    mapping(uint256 => VoucherInfo) public voucherInfo;
    mapping(address => uint256[]) public restaurantVouchers;
    mapping(address => mapping(uint256 => uint256)) public restaurantVoucherIndex;

    /// @notice Evento emitido quando um novo voucher é criado
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
    /// @notice Evento emitido quando um voucher é resgatado
    event VoucherRedeemed(uint256 indexed id, address indexed customer, address indexed restaurant, uint256 amount);

    /// @notice Evento emitido quando o status de um voucher é alterado
    event VoucherStatusChanged(uint256 indexed id, bool isActive);

    /// @notice Evento emitido quando a URI do contrato é atualizada
    event ContractURIChanged(string newContractURI);

    /// @notice Construtor do contrato
    /// @param initialOwner Endereço do proprietário inicial
    /// @param nameRV Nome do contrato de voucher
    /// @param symbolRV Símbolo do contrato de voucher
    /// @param uriContract URI base para metadados do contrato
    constructor(address initialOwner, string memory nameRV, string memory symbolRV, string memory uriContract)
        ERC1155("")
        Ownable(initialOwner)
    {
        name = nameRV;
        symbol = symbolRV;
        contractVoucherURI = uriContract;
    }

    /// @notice Cria um novo voucher
    /// @dev Somente o owner pode criar vouchers
    /// @param dishName Nome do prato/oferta
    /// @param voucherId ID único do voucher
    /// @param price Preço do voucher em wei
    /// @param maxSupply Quantidade máxima disponível
    /// @param saleStart Timestamp de início da venda
    /// @param saleEnd Timestamp de término da venda
    /// @param useBy Timestamp de validade do voucher
    /// @param uriVoucher URI para metadados do voucher
    function createVoucher(
        string calldata dishName,
        uint256 voucherId,
        uint256 price,
        uint256 maxSupply,
        uint64 saleStart,
        uint64 saleEnd,
        uint64 useBy,
        string calldata uriVoucher
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

    /// @notice Cunha tokens de voucher para um endereço
    /// @dev Somente o restaurante proprietário pode chamar
    /// @param to Endereço que receberá os tokens
    /// @param id ID do voucher
    /// @param amount Quantidade de tokens para cunhar
    function mintVoucher(address to, uint256 id, uint256 amount) external whenNotPaused nonReentrant {
        if (voucherInfo[id].restaurant != msg.sender) revert NotVoucherOwner();
        if (amount == 0) revert InvalidSupply();
        if (block.timestamp < voucherInfo[id].saleStart || block.timestamp > voucherInfo[id].saleEnd) {
            revert InvalidSalePeriod();
        }
        if ((voucherInfo[id].currentSupply + amount) > voucherInfo[id].maxSupply) revert ExceedsMaxSupply();
        voucherInfo[id].currentSupply = voucherInfo[id].currentSupply + amount;
        _mint(to, id, amount, "");
    }

    /// @notice Resgata/queima tokens de voucher
    /// @param id ID do voucher
    /// @param amount Quantidade de tokens para resgatar
    function redeemVoucher(uint256 id, uint128 amount) external nonReentrant {
        if (balanceOf(msg.sender, id) < amount) revert InsufficientVouchers();
        if (block.timestamp > voucherInfo[id].useBy) revert VoucherExpired();
        if (!voucherInfo[id].isActive) revert VoucherInactive();

        voucherInfo[id].currentSupply -= amount; // Decrementar o suprimento
        _burn(msg.sender, id, amount);
        emit VoucherRedeemed(id, msg.sender, voucherInfo[id].restaurant, amount);
    }

    /// @notice Cunha múltiplos vouchers em uma única transação
    /// @param to Endereço que receberá os tokens
    /// @param ids Array de IDs dos vouchers
    /// @param amounts Array de quantidades correspondentes
    function batchMintVouchers(address to, uint256[] memory ids, uint256[] memory amounts)
        external
        whenNotPaused
        nonReentrant
    {
        if (ids.length != amounts.length) revert ArraysLengthMismatch();
        if (ids.length == 0) revert EmptyArrays();
        if (ids.length > MAX_BATCH_SIZE) revert BatchTooLarge();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (voucherInfo[id].restaurant != msg.sender) revert NotVoucherOwner();
            if ((voucherInfo[id].currentSupply + amount) > voucherInfo[id].maxSupply) revert ExceedsMaxSupply();
            if (block.timestamp < voucherInfo[id].saleStart || block.timestamp > voucherInfo[id].saleEnd) {
                revert InvalidSalePeriod();
            }

            voucherInfo[id].currentSupply = voucherInfo[id].currentSupply + amount;
        }

        _mintBatch(to, ids, amounts, "");
    }

    /// @notice Retorna a URI de metadados para um voucher específico
    /// @param id ID do voucher
    /// @return URI string dos metadados
    function uri(uint256 id) public view override returns (string memory) {
        return voucherInfo[id].uri;
    }

    /// @notice Retorna todas as informações de um voucher
    /// @param id ID do voucher
    /// @return Estrutura VoucherInfo com todos os dados
    function getVoucherInfo(uint256 id) external view returns (VoucherInfo memory) {
        return voucherInfo[id];
    }

    /// @notice Retorna todos os vouchers de um restaurante
    /// @param restaurant Endereço do restaurante
    /// @return Array de IDs de voucher
    function getVouchersByRestaurant(address restaurant) external view returns (uint256[] memory) {
        return restaurantVouchers[restaurant];
    }

    /// @notice Retorna vouchers de um restaurante com paginação
    /// @param restaurant Endereço do restaurante
    /// @param offset Posição inicial
    /// @param limit Quantidade máxima a retornar
    /// @return Array de IDs de voucher paginado
    function getVouchersByRestaurant(address restaurant, uint256 offset, uint256 limit)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allVouchers = restaurantVouchers[restaurant];
        uint256 length = allVouchers.length;

        if (offset >= length) {
            return new uint256[](0); // Retorna um array vazio se o offset estiver fora dos limites.
        }

        uint256 actualLimit = limit;
        if (offset + limit > length) {
            actualLimit = length - offset;
        }

        uint256[] memory result = new uint256[](actualLimit);
        for (uint256 i = 0; i < actualLimit; i++) {
            result[i] = allVouchers[offset + i];
        }
        return result;
    }

    /// @notice Atualiza o status de ativação de um voucher
    /// @param id ID do voucher
    /// @param isActive Novo status de ativação
    function setVoucherActive(uint256 id, bool isActive) external {
        if (voucherInfo[id].restaurant != msg.sender) revert NotVoucherOwner();
        voucherInfo[id].isActive = isActive;
        emit VoucherStatusChanged(id, isActive);
    }

    /// @notice Retorna a URI de metadados do contrato
    /// @return URI string dos metadados do contrato
    function contractURI() public view returns (string memory) {
        return contractVoucherURI;
    }

    /// @notice Atualiza a URI de metadados do contrato
    /// @dev Somente o owner pode chamar
    /// @param newContractURI Nova URI para metadados
    function setContractURI(string memory newContractURI) external onlyOwner {
        contractVoucherURI = newContractURI;
        emit ContractURIChanged(newContractURI);
    }
    /// @notice Pausa todas as operações do contrato
    /// @dev Somente o owner pode chamar

    function pause() external onlyOwner {
        _pause();
    }
    /// @notice Despausa o contrato
    /// @dev Somente o owner pode chamar

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Função interna de atualização de estado
    /// @dev Sobrescreve a função das extensões ERC1155 e Pausable
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable)
    {
        super._update(from, to, ids, values);
    }

    /// @notice Verifica suporte a interfaces
    /// @dev Implementa ERC-165
    /// @param interfaceId ID da interface a verificar
    /// @return bool Indicando suporte
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return interfaceId == type(IERC1155MetadataURI).interfaceId || super.supportsInterface(interfaceId);
    }
}
