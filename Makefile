-include .env
.PHONY: help build install test

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo " make deploy [ARGS-...]"

build:; forge build

install:; forge install chainaccelorg/foundry-devops@0.0.11 --no-commit && \
	forge install smartcontractkit/chainlink-brownie-contracts@.6.1 --no-commit && \
	forge install tranmissions11/solmate@v6 --no-commit && \
	forge install tranmissions11/solmate@v6 --no-commit

test:; forge test

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY)

# if --network sepolia is used, then use sepolia stuff, otherwise anvil stuff
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)