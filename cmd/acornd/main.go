package main

import (
	"os"

	"github.com/cosmos/cosmos-sdk/server"

	"github.com/acorn-chain/acorn/app"
	"github.com/acorn-chain/acorn/cmd/acornd/cmd"
	svrcmd "github.com/cosmos/cosmos-sdk/server/cmd"
)

func main() {
	rootCmd, _ := cmd.NewRootCmd()
	if err := svrcmd.Execute(rootCmd, "", app.DefaultNodeHome); err != nil {
		switch e := err.(type) {
		case server.ErrorCode:
			os.Exit(e.Code)

		default:
			os.Exit(1)
		}
	}
}
