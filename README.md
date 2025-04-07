# Projeto Restaurant Voucher NFT

## 1. Visão Geral do Projeto

O **Restaurant Voucher NFT** é uma solução blockchain inovadora que permite a criação e gestão de vouchers digitais para restaurantes utilizando tokens não-fungíveis (NFTs) no padrão ERC-1155.

### 1.1 Objetivos Principais
- Digitalizar vouchers de restaurantes como NFTs seguros e verificáveis
- Automatizar processos de emissão e resgate de vouchers
- Garantir transparência e imutabilidade das transações
- Oferecer controle total aos restaurantes sobre suas ofertas

### 1.2 Tecnologias Utilizadas
- **Blockchain**: Ethereum (compatível com EVM)
- **Padrão de Token**: ERC-1155 (semi-fungível)
- **Linguagem**: Solidity 0.8.28
- **Frameworks**: OpenZeppelin Contracts
- **Ferramentas**: Foundry para desenvolvimento e testes

## 2. Arquitetura do Sistema

### 2.1 Componentes Principais

#### Contrato Inteligente
```solidity
contract RestaurantVoucherNFT is ERC1155, Ownable, ERC1155Pausable, ReentrancyGuard {
    // Implementação principal
}
```

#### Funcionalidades-Chave:
- Criação de vouchers com parâmetros personalizados
- Cunhagem e distribuição de vouchers
- Resgate e queima de vouchers
- Gestão de pausa de emergência
- Controle de acesso granular

### 2.2 Diagrama de Fluxo

```
Restaurante
  │
  ├─ Cria Voucher (createVoucher)
  │   └─ Define: preço, validade, quantidade
  │
  ├─ Distribui Vouchers (mintVoucher/batchMint)
  │   └─ Para clientes específicos
  │
  └─ Gerencia Status (setVoucherActive)

Cliente
  │
  └─ Resgata Voucher (redeemVoucher)
      └─ Queima NFT para usar oferta
```

## 3. Funcionalidades Detalhadas

### 3.1 Criação de Vouchers
- **Parâmetros Configuráveis**:
  - Nome do prato
  - Preço em ETH
  - Quantidade máxima
  - Período de venda (start/end)
  - Data de validade
  - URI de metadados

- **Restrições**:
  - Máximo de 100 vouchers por restaurante
  - Períodos devem ser sequenciais (venda → validade)
  - Apenas o dono pode criar

### 3.2 Distribuição de Vouchers
- **Mint Individual**:
  - Para endereços específicos
  - Verificação de período de venda
  - Controle de estoque

- **Mint em Lote**:
  - Até 100 vouchers por transação
  - Eficiência de gas para operações em massa

### 3.3 Resgate de Vouchers
- **Processo Seguro**:
  - Verificação de saldo
  - Checagem de validade
  - Queima do token NFT
  - Atualização de estoque

## 4. Modelo de Dados

### 4.1 Estrutura do Voucher (VoucherInfo)
```solidity
struct VoucherInfo {
    address restaurant;  // Dono do voucher
    uint64 saleStart;    // Início da venda
    uint64 saleEnd;      // Fim da venda
    uint64 useBy;        // Data de expiração
    uint256 price;       // Preço em wei
    uint256 maxSupply;   // Quantidade máxima
    uint256 currentSupply; // Quantidade emitida
    bool isActive;       // Status
    string dishName;     // Nome do prato
    string uri;          // Metadados
}
```

### 4.2 Armazenamento
- `voucherInfo`: Mapeamento ID → dados completos
- `restaurantVouchers`: Lista de IDs por restaurante
- `restaurantVoucherIndex`: Índice para busca eficiente

## 5. Segurança e Conformidade

### 5.1 Medidas de Segurança
- **Proteção contra Reentrância**: Uso de ReentrancyGuard
- **Pausa de Emergência**: Funções pausáveis
- **Validações Rigorosas**: Verificação de todos os parâmetros
- **Controle de Acesso**: Restrições por função

### 5.2 Conformidade com Padrões
- **ERC-1155**: Suporte completo ao padrão
- **ERC-165**: Detecção de interfaces
- **Best Practices**: Segue padrões OpenZeppelin

## 6. Interface e Integração

### 6.1 Métodos Principais

| Função                | Descrição                                  | Acesso       |
|-----------------------|-------------------------------------------|-------------|
| createVoucher()       | Cria novo voucher                         | Owner       |
| mintVoucher()         | Emite voucher para cliente                | Restaurante |
| redeemVoucher()       | Resgata/usa voucher                       | Cliente     |
| batchMintVouchers()   | Emite múltiplos vouchers                  | Restaurante |
| setVoucherActive()    | Ativa/desativa voucher                    | Restaurante |

### 6.2 Eventos

| Evento                | Descrição                                  |
|-----------------------|-------------------------------------------|
| VoucherCreated        | Emitido ao criar novo voucher             |
| VoucherRedeemed       | Quando um voucher é resgatado             |
| VoucherStatusChanged  | Status do voucher alterado                |
| ContractURIChanged    | URI de metadados do contrato atualizada   |

## 7. Casos de Uso

### 7.1 Para Restaurantes
- Criar ofertas sazonais como NFTs
- Controlar períodos de validade
- Gerenciar estoque de forma transparente
- Distribuir vouchers para clientes fiéis

### 7.2 Para Clientes
- Adquirir vouchers exclusivos
- Verificar autenticidade na blockchain
- Resgatar ofertas de forma segura
- Colecionar vouchers especiais

## 8. Implementação e Deploy

### 8.1 Requisitos
- Compilador Solidity 0.8.28
- Ambiente EVM (Ethereum, Polygon, etc.)
- Wallet com fundos para deploy

### 8.2 Passos para Deploy
1. Compilar contrato:
```bash
forge build
```

2. Realizar deploy:
```bash
forge create --rpc-url [RPC_URL] \
  --constructor-args [OWNER_ADDRESS] "Restaurant Vouchers" "RVO" "https://api.example.com/v1/" \
  --private-key [PK] \
  src/RestaurantVoucherNFT.sol:RestaurantVoucherNFT
```

## 9. Roadmap e Melhorias Futuras

### 9.1 Próximas Fases
- Integração com sistemas de pagamento
- Marketplace secundário para vouchers
- Programa de fidelidade baseado em NFTs
- Interoperabilidade com outras redes

### 9.2 Aprimoramentos
- Royalties para criadores
- Vouchers colecionáveis
- Integração com oráculos para preços dinâmicos

## 10. Conclusão

O Restaurant Voucher NFT oferece uma solução completa para digitalização de vouchers de restaurantes, combinando a segurança da blockchain com a flexibilidade do padrão ERC-1155. O sistema proporciona benefícios tanto para estabelecimentos quanto para clientes, trazendo transparência, eficiência e novas possibilidades para o setor gastronômico.




# DESENVOLVIMENTO

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
### Test Report

```shell
forge coverage --report lcov
genhtml lcov.info --output-dir coverage
```

### Format

```shell
$ forge fmt
```
### Deploy

```shell
$ forge script script/RestaurantVoucherNFT.s.sol:RestaurantVoucherNFTScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## PROMPT PARA AUDITAR:
Como auditor de smart contracts e desenvolvedor experiente na área, realize uma auditoria detalhada deste contrato inteligente. Identifique vulnerabilidades de segurança, riscos potenciais e pontos de otimização. Além disso, sugira melhorias de código,boas práticas e aprimoramentos para eficiência de gas, conformidade com padrões do setor e escalabilidade.