package audit

import (
	"context"
	"encoding/csv"
	"log"
	"net/http"
	"os"

	"github.com/google/go-github/github"
	"github.com/spf13/cobra"
	"golang.org/x/oauth2"
)

func writeReposToTextFile(repos []string) {
	// create a csv file and write the user to it
	file, err := os.Create("repos_audited.txt")
	if err != nil {
		panic(err)
	}

	defer file.Close()

	//create new csv writer
	writer := csv.NewWriter(file)

	defer writer.Flush()

	// loop through repos and write them to the csv file
	for _, repo := range repos {
		_ = writer.Write([]string{repo})
	}
}

func Cmd() *cobra.Command {
	return auditCmd
}

// auditCmd represents the audit command
var auditCmd = &cobra.Command{
	Use:   "audit",
	Short: "Audit repositories containing LFS objects and write them into a text file",
	Run: func(cmd *cobra.Command, args []string) {
		patToken, err := cmd.Flags().GetString("pat-token")
		if err != nil {
			log.Fatalf("Unable to retrieve PAT Token: %v", err)
		}
		orgName, err := cmd.Flags().GetString("org-name")
		if err != nil {
			log.Fatalf("Unable to retrieve organization name: %v", err)
		}
		isEnterpriseServer, err := cmd.Flags().GetBool("is-enterprise-server")
		if err != nil {
			log.Fatalf("Unable to retrieve is-enterprise-server flag: %v", err)
		}
		var client *github.Client
		ctx := context.Background()
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: patToken},
		)
		tc := oauth2.NewClient(ctx, ts)

		// create github client with oauth
		if isEnterpriseServer {
			enterpriseServerUrl, err := cmd.Flags().GetString("enterprise-server-url")
			if err != nil {
				log.Fatalf("Unable to retrieve enterprise-server-url flag: %v", err)
			}
			client, err = github.NewEnterpriseClient(enterpriseServerUrl, enterpriseServerUrl, tc)
			if err != nil {
				log.Fatalf("Unable to create enterprise client: %v", err)
			}
		} else {
			client = github.NewClient(tc)
		}

		// get all repos in the organization
		var repos []*github.Repository
		opts := &github.RepositoryListByOrgOptions{
			ListOptions: github.ListOptions{PerPage: 100},
		}
		for {
			_repos, resp, err := client.Repositories.ListByOrg(ctx, orgName, opts)
			if err != nil {
				if resp.StatusCode == http.StatusNotFound {
					log.Fatalf("Organization %s does not exist. Error: %v", orgName, err)
				}
				log.Fatalf("Unable to query org repos: %v", err)
			}
			repos = append(repos, _repos...)
			if resp.NextPage == 0 {
				break
			}
			opts.Page = resp.NextPage
		}

		// declare slice of strings to hold repo URLs
		var repoURLs []string

		// iterate through repos and get contents
		for _, repo := range repos {
			_, _, resp, err := client.Repositories.GetContents(ctx, orgName, repo.GetName(), ".gitattributes", nil)
			if err == nil && resp.StatusCode != http.StatusNotFound {
				repoURLs = append(repoURLs, repo.GetHTMLURL())
			}
		}

		if len(repoURLs) > 0 {
			log.Println("Repositories with LFS objects were found, writing audit results to text file")
			writeReposToTextFile(repoURLs)
		} else {
			log.Println("No repositories with LFS objects were found")
		}
	},
}
