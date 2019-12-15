var HoldableERC20 = artifacts.require("HoldableERC20");

module.exports = function(deployer) {
  deployer.deploy(HoldableERC20);
};
