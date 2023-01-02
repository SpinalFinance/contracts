// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IStakingPool} from "./interfaces/IStakingPool.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IStkFIL} from "./interfaces/IStkFIL.sol";

contract StakingPool is IStakingPool {
    struct UserInfo {
        uint256 amount;     // How many validators the user has provided.
        uint256 rewardDebt; // Reward debt
    }

    IERC20 public pstake;

    // IUniswapRouter public router;

    address public WETH;

    IStkFIL public stkEth;

    ICore public core;

    IPriceOracle public oracle;

    uint256 public accRewardPerValidator;

    uint256 public DEVIATION; // 5% deviation is acceptable
    uint256 public constant BASIS_POINT = 10000;

    event RewardRedeemed(uint256 amount, address node_operator);
    event FeeReceived(uint256 amount);

    mapping(address => UserInfo) public userInfos;

    function initialize(
        IPriceOracle _oracle,
        IERC20 _pstake,
        IUniswapRouter _router,
        ICore _core,
        address _weth)
    public initializer
    {
        require(_weth != address(0), "Invalid weth address");
        __Ownable_init();
        oracle = _oracle;
        pstake = _pstake;
        core = _core;
        stkEth = core.stkEth();
        router = _router;
        WETH = _weth;
        DEVIATION = 500;
    }

    receive() external payable {
        emit FeeReceived(msg.value);
    }

    function stakePriorityFee() external override returns (bool){
        if (address(this).balance == 0) {
            return false;
        }
        uint256 stkETHPriorityFee = (address(this).balance * 1e18) / stkEth.pricePerShare();
        Issuer(core.issuer()).stake{value : address(this).balance}();
        stkEth.burn(address(this), stkETHPriorityFee);
        return true;
    }

    function updateRewardPerValidator(uint256 newReward) public override {

        uint256 totalValidators = IOracle(core.oracle()).activatedValidators() + IIssuer(core.issuer()).pendingValidators();

        require(stkEth.transferFrom(_msgSender(), address(this), newReward), "Transfer failed");

        accRewardPerValidator += newReward * 1e12 / totalValidators;
    }

    function claimAndUpdateRewardDebt(address usr) external override {

        UserInfo storage user = userInfos[usr];

        uint256 userValidators = IKeysManager(core.keysManager()).nodeOperatorValidatorCount(usr);

        uint256 pending = (accRewardPerValidator * user.amount / 1e12) - user.rewardDebt;

        if (pending > 0) {
            stkEth.transfer(usr, pending);
            emit RewardRedeemed(pending, usr);
        }

        user.rewardDebt = accRewardPerValidator * userValidators / 1e12;
        user.amount = userValidators;
    }

    // keeping this for future insurance mechanism
    function slash(uint256 amount) external override {

        require(_msgSender() == core.oracle(), "StakingPool: only oracle can call to slash");

        uint256 pstakeBalance = pstake.balanceOf(address(this));

        if (pstakeBalance == 0) {
            return;
        }
        uint256 pstakePrice = oracle.price();
        address[] memory path = new address[](3);
        path[0] = address(pstake);
        path[1] = WETH;
        path[2] = address(stkEth);
        uint256[] memory amountsIn = router.getAmountsIn(amount, path);

        if (!validateDeviation(pstakePrice, amountsIn[0], amount)) {
            return;
        }

        if (amountsIn[0] > pstakeBalance) {
            pstake.approve(address(router), pstakeBalance);
            router.swapExactTokensForTokens(pstakeBalance, 0, path, address(this), block.timestamp + 100);
        } else {
            pstake.approve(address(router), amountsIn[0]);
            router.swapTokensForExactTokens(amount, amountsIn[0], path, address(this), block.timestamp + 100);
        }

        stkEth.burn(address(this), stkEth.balanceOf(address(this)));

    }

    function validateDeviation(uint256 price, uint256 amountIn, uint256 amountOut) internal view returns (bool) {

        uint256 tradePrice = amountIn * 1e18 / amountOut;

        return tradePrice <= price * (BASIS_POINT + DEVIATION) / BASIS_POINT &&
        tradePrice >= price * (BASIS_POINT - DEVIATION) / BASIS_POINT;

    }

    function numOfValidatorAllowed(address usr) public view override returns (uint256) {

        return type(uint256).max;
    }  
}