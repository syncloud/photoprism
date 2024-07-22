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
		Use:          "install",
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := log.SysLogger(fmt.Sprint(installer.App, ":install"))
			return installer.New(logger).Install()
		},
	}

	err := rootCmd.Execute()
	if err != nil {
		fmt.Print(err)
		os.Exit(1)
	}
}
