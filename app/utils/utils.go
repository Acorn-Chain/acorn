package utils

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	"strings"
)

const (
	AcornExponent = 6
	BaseCoinUnit  = "ueacorn"
)

var (
	// DevnetChainID defines the Acorn chain ID for devnet
	DevnetChainID = "acorn-testnet"
)

// IsDevnet returns true if the chain-id has the Acorn devnet chain prefix.
func IsDevnet(chainID string) bool {
	return strings.HasPrefix(chainID, DevnetChainID)
}

// RegisterDenoms registers token denoms.
func RegisterDenoms() {
	err := sdk.RegisterDenom(BaseCoinUnit, sdk.NewDecWithPrec(1, AcornExponent))
	if err != nil {
		panic(err)
	}
}
