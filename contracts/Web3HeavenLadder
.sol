// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IWeb3HeavenFactory.sol";
import "./interfaces/IWeb3Heaven.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Web3HeavenLadder is Ownable, ReentrancyGuard {

    address public FIVE_DEGREES;
    address public FACTORY;
    address payable public FUND;
    uint256 public MONUMENT_ID;
    mapping(uint256 => address) public HEAVEN;
    uint256 public APPLY_NEED_DONATE;

    event Apply(address applicant, address monument, uint256 id);

    constructor(address _degrees, address _factory, address payable _fund, address _owner) public {
        FIVE_DEGREES = _degrees;
        FACTORY = _factory;
        FUND = _fund;
        initializeOwner(_owner);
        MONUMENT_ID = 1;
    }

    function setDonate(uint256 _donate) public onlyOwner {
        APPLY_NEED_DONATE = _donate;
    }

    function setFund(address payable _fund) public onlyOwner {
        FUND = _fund;
    }

    function applyMonument(string memory _name, string memory _image, string memory _properties) external payable nonReentrant returns (address monument, uint256 id) {
        if (APPLY_NEED_DONATE > 0) {
            require(msg.value >= APPLY_NEED_DONATE, "Web3Heaven: INVALID_msg.value");
            FUND.transfer(msg.value);
        }
        id = MONUMENT_ID;
        monument = IWeb3HeavenFactory(FACTORY).createMonument(msg.sender, id);
        IWeb3Heaven(monument).initialize(FIVE_DEGREES, _name, _image, _properties);
        HEAVEN[id] = monument;
        MONUMENT_ID += 1;
        emit Apply(msg.sender, monument, id);
    }

}