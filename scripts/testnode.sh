#!/bin/bash

CHAINID="${CHAIN_ID:-acorn_9332-1}"
MONIKER="localtestnet"
KEYRING="test"      # remember to change to other types of keyring like 'file' in-case exposing to outside world, otherwise your balance will be wiped quickly. The keyring test does not require private key to steal tokens from you
KEYALGO="secp256k1" #gitleaks:allow
LOGLEVEL="debug"
# to trace evm
#TRACE="--trace"
TRACE=""
PRUNING="default"
#PRUNING="custom"

CHAINDIR="$HOME/.acorn"
GENESIS="$CHAINDIR/config/genesis.json"
TMP_GENESIS="$CHAINDIR/config/tmp_genesis.json"
APP_TOML="$CHAINDIR/config/app.toml"
CONFIG_TOML="$CHAINDIR/config/config.toml"

rm -r $CHAINDIR/*

# feemarket params basefee: 10^8
BASEFEE=100000000

VAL_KEY="mykey"

# validate dependencies are installed
command -v jq >/dev/null 2>&1 || {
  echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"
  exit 1
}

# used to exit on first error (any non-zero exit code)
set -e

# Set client config
acornd config keyring-backend "$KEYRING"
acornd config chain-id "$CHAINID"

# Add keyring
acornd keys add "$VAL_KEY" --keyring-backend "$KEYRING" --algo "$KEYALGO"

# Store the validator address in a variable to use it later
node_address=$(acornd keys show -a "$VAL_KEY")

# Set moniker and chain-id for Evmos (Moniker can be anything, chain-id must be an integer)
acornd init "$MONIKER" --chain-id "$CHAINID"

# Change parameter token denominations to uacorn
jq '.app_state.staking.params.bond_denom="uacorn"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state.mint.params.mint_denom="uacorn"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state.crisis.constant_fee.denom="uacorn"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state.gov.deposit_params.min_deposit[0].denom="uacorn"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state.gov.deposit_params.min_deposit[0].amount="1000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state.gov.params.min_deposit[0].denom="uacorn"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state.gov.params.min_deposit[0].amount="1000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state.evm.params.evm_denom="aacorn"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state.inflation.params.mint_denom="uacorn"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

# set gov proposing && voting period
jq '.app_state.gov.deposit_params.max_deposit_period="10s"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state.gov.voting_params.voting_period="10s"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

# When upgrade to cosmos-sdk v0.47, use gov.params to edit the deposit params
# check if the 'params' field exists in the genesis file
if jq '.app_state.gov.params != null' "$GENESIS" | grep -q "true"; then
  jq '.app_state.gov.params.min_deposit[0].denom="uacorn"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
  jq '.app_state.gov.params.max_deposit_period="10s"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
  jq '.app_state.gov.params.voting_period="10s"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
fi

# Set gas limit in genesis
jq '.consensus_params.block.max_gas="10000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

# Set base fee in genesis
jq '.app_state["feemarket"]["params"]["base_fee"]="'${BASEFEE}'"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

# disable produce empty block
sed -i.bak 's/create_empty_blocks = true/create_empty_blocks = false/g' "$CONFIG_TOML"

# Allocate genesis accounts (cosmos formatted addresses)
acornd add-genesis-account "$(acornd keys show "$VAL_KEY" -a --keyring-backend "$KEYRING")" 100000000000000uacorn --keyring-backend "$KEYRING"

acornd add-genesis-account "acorn185tq49mv3z4djar3k874rju6cnm3nvrhfma3w9" 2000000000uacorn

# Update total supply with claim values
total_supply=100002000000000
jq -r --arg total_supply "$total_supply" '.app_state.bank.supply[0].amount=$total_supply' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq -r '.app_state.bank.supply[0].denom="uacorn"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

# set list of evm precompile contracts
jq '.app_state.evm.params.active_precompiles=[]' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

# set custom pruning settings
if [ "$PRUNING" = "custom" ]; then
  sed -i.bak 's/pruning = "default"/pruning = "custom"/g' "$APP_TOML"
  sed -i.bak 's/pruning-keep-recent = "0"/pruning-keep-recent = "2"/g' "$APP_TOML"
  sed -i.bak 's/pruning-interval = "0"/pruning-interval = "10"/g' "$APP_TOML"
  sed -i.bak 's/swagger = false/swagger = true/g' "$APP_TOML"
fi

# make sure the localhost IP is 0.0.0.0
sed -i.bak 's/localhost/0.0.0.0/g' "$CONFIG_TOML"
sed -i.bak 's/127.0.0.1/0.0.0.0/g' "$CONFIG_TOML"
sed -i.bak 's/127.0.0.1/0.0.0.0/g' "$APP_TOML"
sed -i.bak 's/localhost/0.0.0.0/g' "$APP_TOML"

# use timeout_commit 1s to make test faster
sed -i.bak 's/timeout_commit = "3s"/timeout_commit = "1s"/g' "$CONFIG_TOML"

# Sign genesis transaction
acornd gentx "$VAL_KEY" 1000000000uacorn --gas-prices ${BASEFEE}uacorn --keyring-backend "$KEYRING" --chain-id "$CHAINID"

# Enable the APIs for the tests to be successful
sed -i.bak '119s/enable = false/enable = true/g' "$APP_TOML"
sed -i.bak 's/swagger = false/swagger = true/g' "$APP_TOML"

# Don't enable memiavl by default
grep -q -F '[memiavl]' "$APP_TOML" && sed -i.bak '/\[memiavl\]/,/^\[/ s/enable = true/enable = false/' "$APP_TOML"

# Collect genesis tx
acornd collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
acornd validate-genesis

# Start the node
acornd start "$TRACE" \
  --log_level $LOGLEVEL \
  --minimum-gas-prices=0.0001uacorn \
  --json-rpc.api eth,txpool,personal,net,debug,web3 \
  --json-rpc.enable
# --chain-id "$CHAINID"
