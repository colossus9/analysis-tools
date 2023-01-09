/*
Copyright © 2021 NAME HERE <EMAIL ADDRESS>

*/
package main

import (
	"LFSAudit/internal/audit"
	"log"
	"os"

	"github.com/spf13/cobra"
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "LFSAudit",
	Short: "A brief description of your application",
	Long: `A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	// Uncomment the following line if your bare application
	// has an action associated with it:
	// Run: func(cmd *cobra.Command, args []string) { },
}

func main() {
	auditCmd := audit.Cmd()
	auditCmd.Flags().String("pat-token", "", "PAT token to use")
	auditCmd.Flags().String("org-name", "", "Name of the organization")
	auditCmd.Flags().Bool("is-enterprise-server", false, "Is the GitHub server an enterprise server")
	auditCmd.Flags().String("enterprise-server-url", "", "GitHub Enterprise server URL")

	err := auditCmd.MarkFlagRequired("pat-token")
	if err != nil {
		log.Fatal(err)
	}
	err = auditCmd.MarkFlagRequired("org-name")
	if err != nil {
		log.Fatal(err)
	}

	rootCmd.AddCommand(audit.Cmd())
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	err = rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}
