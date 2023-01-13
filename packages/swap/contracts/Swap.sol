// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenSwap {
    address payable public recipient;
    mapping(address => uint256) public balances;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    constructor() public {
        name = "FIL";
        symbol = "FIL";
        decimals = 18;
        totalSupply = 1000000000000000000;
    }

    function swap(address payable _recipient, uint256 _value) public {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] -= _value;
        recipient = _recipient;
        recipient.transfer(_value);
    }

    function approve(address _spender, uint256 _value) public {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] -= _value;
        balances[_spender] += _value;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
}

