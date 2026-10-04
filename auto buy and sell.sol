// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPov {
    function buy(uint256 marketId, bool yes, uint256 minTokens) external payable;
    function sell(uint256 marketId, bool yes, uint256 amount, uint256 minProceeds) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

contract PovRoundTrip {
    IPov public constant POV =
        IPov(0xd4f4619bb4590598C778178690b77C589b93A3eB);

    event Flipped(uint256 marketId, bool yes, uint256 tokens, uint256 ethBack);

    receive() external payable {}

    function flip(
        uint256 marketId,
        bool yes,
        address token,
        uint256 minTokens,
        uint256 minProceeds
    ) external payable {
        require(msg.value > 0, "no eth");

        POV.buy{value: msg.value}(marketId, yes, minTokens);

        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, "no tokens minted");

        IERC20(token).approve(address(POV), amount);
        POV.sell(marketId, yes, amount, minProceeds);

        uint256 back = address(this).balance;
        if (back > 0) {
            (bool ok, ) = msg.sender.call{value: back}("");
            require(ok, "refund fail");
        }

        emit Flipped(marketId, yes, amount, back);
    }
}
