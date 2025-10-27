package keeper

import (
	"github.com/acorn-chain/acorn/x/acorn/types"
)

var _ types.QueryServer = Keeper{}
