KEY="mykey"
CHAINID="acorn_9332-1"
MONIKER="localtestnet"
KEYALGO="secp256k1"
KEYRING="test"
LOGLEVEL="info"
# to trace evm
#TRACE="--trace"
TRACE=""

# validate dependencies are installed
command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

# remove existing daemon
rm -rf ~/.acorn*

acornd config keyring-backend $KEYRING
acornd config chain-id $CHAINID

# if $KEY exists it should be deleted
acornd keys add $KEY --keyring-backend $KEYRING --algo $KEYALGO

# Set moniker and chain-id for Evmos (Moniker can be anything, chain-id must be an integer)
acornd init $MONIKER --chain-id $CHAINID

# Change denom from stake to uacorn in genesis file
sed -i'' -e 's/"stake"/"uacorn"/g' ~/.acorn/config/genesis.json

# Enable evm rpc API
sed -i'' -e "286s/enable = false/enable = true/" ~/.acorn/config/app.toml

# Allocate genesis accounts (cosmos formatted addresses)
acornd add-genesis-account $KEY 10000000000000000uacorn --keyring-backend $KEYRING

# Sign genesis transaction
acornd gentx $KEY 100000000000000uacorn --keyring-backend $KEYRING --chain-id $CHAINID

# Collect genesis tx
acornd collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
acornd validate-genesis

if [[ $1 == "pending" ]]; then
  echo "pending mode is on, please wait for the first block committed."
fi

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
acornd start --pruning=nothing  --minimum-gas-prices=0.0001acorn
