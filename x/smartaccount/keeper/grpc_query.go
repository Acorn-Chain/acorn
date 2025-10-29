package keeper

import (
	typesv1 "github.com/acorn-chain/acorn/x/smartaccount/types/v1beta1"
)

var _ typesv1.QueryServer = Keeper{}
