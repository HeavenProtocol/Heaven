// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IFiveDegrees.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC1155Receiver.sol";

contract Web3Heaven is IERC721Receiver, IERC1155Receiver {

    bool public init;

    event RIP(address indexed operator, address indexed from, uint tokenId, uint256 value, uint256 NFT, bytes data);
    event RIP(address indexed operator, address indexed from, uint[] tokenId, uint256[] value, uint256 NFT, bytes data);

    function initialize(address _degrees, string memory _name, string memory _image, string memory _properties) external {
        require(!init, "invalid init");
        IFiveDegrees(_degrees).setInfo(_name, _image, _properties);
        init = true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit RIP(operator, from, tokenId, 1, 721, data);
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        emit RIP(operator, from, id, value, 1155, data);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        emit RIP(operator, from, ids, values, 1155, data);
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}