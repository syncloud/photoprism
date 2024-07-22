package main

import (
	"fmt"
	"github.com/spf13/cobra"
	"hooks/installer"
	"hooks/log"
	"os"
)

func main() {
	var rootCmd = &cobra.Command{
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := log.SysLogger(fmt.Sprint(installer.App, ":pre-refresh"))
			return installer.New(logger).PreRefresh()
		},
	}

	err := rootCmd.Execute()
	if err != nil {
		fmt.Print(err)
		os.Exit(1)
	}
}
