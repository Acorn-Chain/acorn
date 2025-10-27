package app

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/x/auth/posthandler"
)

type PostHandlerOptions struct {
	posthandler.HandlerOptions
}

func NewPostHandler(options PostHandlerOptions) (sdk.PostHandler, error) {
	postDecorators := []sdk.PostDecorator{
	}

	return sdk.ChainPostDecorators(postDecorators...), nil
}
