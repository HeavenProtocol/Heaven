// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./TransferHelper.sol";
import "./Base64.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract Web3TributeMarket is ERC1155, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    struct Tribute {
        string name;
        string image;
        string description;
    }

    struct TributeSetting {
        address owner;
        address token;
        uint256 tokenId;
        uint256 pay;
        uint256 tax;
        bool canBuy;
        uint256 sales;
        Tribute tri;
    }

    mapping(uint256 => address) public PAY_TOKEN;
    mapping(uint256 => uint256) public PAY_TAX;
    mapping(uint256 => Tribute) public THE_TRIBUTES;
    mapping(uint256 => address) public THE_TRIBUTES_OWNER;
    mapping(uint256 => bool) public THE_TRIBUTE_CAN_BUY;
    mapping(uint256 => uint256) public THE_TRIBUTE_SALES;
    mapping(string => address) public THE_TRIBUTE_CHANNEL;
    //Tribute Add Need Pay, just BNB
    uint256 public THE_TRIBUTES_TAX;
    //Tribute Owner Got Tax Rate
    uint256 public THE_ADD_RATE;
    //Sale Channel Got Back Rate
    uint256 public THE_CHANNEL_RATE;
    uint256 public THE_TRIBUTE_ID;
    address public FUND_RECEIVER;

    event BuyTribute(address indexed from, address indexed to, address indexed token, uint256 pay, uint256 tax, uint256 channel, uint256 fund, uint256 time);

    constructor(string memory uri_, address OWNER_, address _fund) ERC1155(uri_) {
        THE_TRIBUTE_ID = 1;
        initializeOwner(OWNER_);
        FUND_RECEIVER = _fund;
    }

    function setTaxAndRate(uint256 add_rate, uint256 channel_rate) public onlyOwner {
        require(add_rate <= 5000, "Web3TributeMarket: more than 5000");
        require(channel_rate <= 1000, "Web3TributeMarket: more than 1000");

        THE_ADD_RATE = add_rate;
        THE_CHANNEL_RATE = channel_rate;
    }

    function queryTributeSettingForId(uint256[] memory tokenIds) public view returns (TributeSetting[] memory tris) {
        tris = new TributeSetting[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            tris[i] = TributeSetting(THE_TRIBUTES_OWNER[id], PAY_TOKEN[id], id, PAY_TAX[id], THE_ADD_RATE, THE_TRIBUTE_CAN_BUY[id], THE_TRIBUTE_SALES[id], THE_TRIBUTES[id]);
        }
    }

    function addTribute(Tribute memory tri, address token, uint256 tax) public payable nonReentrant returns (uint256 id) {
        if (THE_TRIBUTES_TAX > 0 && msg.sender != owner()) {
            require(msg.value >= THE_TRIBUTES_TAX, "Web3TributeMarket: invalid msg.value");
        }
        id = THE_TRIBUTE_ID;
        THE_TRIBUTES[id] = tri;
        THE_TRIBUTE_CAN_BUY[id] = true;
        PAY_TOKEN[id] = token;
        PAY_TAX[id] = tax;
        THE_TRIBUTE_ID += 1;
        THE_TRIBUTES_OWNER[id] = msg.sender;
    }

    function removeTribute(uint256[] memory ids) public {
        for (uint256 i; i < ids.length; i++) {
            require(msg.sender == THE_TRIBUTES_OWNER[ids[i]] || msg.sender == owner(), "Web3TributeMarket: invalid tribute owner");
            THE_TRIBUTES_OWNER[ids[i]] = address(0);
            THE_TRIBUTE_CAN_BUY[ids[i]] = false;
        }
    }

    function addChannel(string memory channel, address receiver) public {
        require(THE_TRIBUTE_CHANNEL[channel] == address(0), "Web3TributeMarket: channel is exist");
        THE_TRIBUTE_CHANNEL[channel] = receiver;
    }

    function removeChannel(string memory channel) public onlyOwner {
        require(THE_TRIBUTE_CHANNEL[channel] != address(0), "Web3TributeMarket: channel not exist");
        THE_TRIBUTE_CHANNEL[channel] = address(0);
    }

    function buyTributeBatch(uint256[] memory ids, uint256[] memory values, string memory channel, address[] memory to) public payable nonReentrant {
        require(ids.length == values.length, "Web3TributeStore: invalid buy data");
        require(ids.length == to.length, "Web3TributeStore: invalid buy data");
        for (uint256 i; i < ids.length; i++) {
            buyTribute(ids[i], values[i], channel, to[i]);
        }
    }

    function buyTribute(uint256 id, uint256 value, string memory channel, address to) public payable nonReentrant returns (uint256 tax) {
        require(THE_TRIBUTE_CAN_BUY[id], "Web3TributeMarket: Tribute removed");
        uint256 taxBack;
        uint256 channelBack;
        uint256 fund;
        if (PAY_TAX[id] > 0) {
            tax = PAY_TAX[id] * value;
            if (PAY_TOKEN[id] == address(0)) {
                require(msg.value >= tax, "Web3TributeMarket: Buy Tribute invalid msg.value");
            } else {
                TransferHelper.safeTransferFrom(PAY_TOKEN[id], msg.sender, address(this), tax);
            }
            (taxBack, channelBack, fund) = paymentHandler(PAY_TOKEN[id], channel, tax, id);
        }
        if (to == address(0)) {
            to = msg.sender;
        }
        _mint(to, id, value, "");
        THE_TRIBUTE_SALES[id] += value;
        emit BuyTribute(msg.sender, to, PAY_TOKEN[id], tax, taxBack, channelBack, fund, block.timestamp);
    }

    function paymentHandler(address _token, string memory _channel, uint256 _tax, uint256 _id) internal returns (uint256 taxBack, uint256 channelBack, uint256 fund) {
        taxBack = _tax.mul(THE_ADD_RATE).div(10000);
        if (taxBack > 0) {
            if (_token != address(0)) {
                TransferHelper.safeTransfer(_token, THE_TRIBUTES_OWNER[_id], taxBack);
            } else {
                TransferHelper.safeTransferETH(THE_TRIBUTES_OWNER[_id], taxBack);
            }
        }
        channelBack = _tax.mul(THE_CHANNEL_RATE).div(10000);
        if (channelBack > 0 && THE_TRIBUTE_CHANNEL[_channel] != address(0)) {
            if (_token != address(0)) {
                TransferHelper.safeTransfer(_token, THE_TRIBUTE_CHANNEL[_channel], channelBack);
            } else {
                TransferHelper.safeTransferETH(THE_TRIBUTE_CHANNEL[_channel], channelBack);
            }
        }
        fund = _tax.sub(taxBack).sub(channelBack);
        if (fund > 0) {
            if (_token != address(0)) {
                TransferHelper.safeTransfer(_token, FUND_RECEIVER, fund);
            } else {
                TransferHelper.safeTransferETH(FUND_RECEIVER, fund);
            }
        }
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        Tribute memory tri = THE_TRIBUTES[tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        tri.name,
                        '", ',
                        '"image": "',
                        tri.image,
                        '", ',
                        '"description": "',
                        tri.description,
                        '" }'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

}