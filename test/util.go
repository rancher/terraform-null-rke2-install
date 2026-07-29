package test

import (
	"context"
	"fmt"

	//"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/google/go-github/v53/github"
	aws "github.com/gruntwork-io/terratest/modules/aws"
	g "github.com/gruntwork-io/terratest/modules/git"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/hashicorp/go-version"
	"github.com/stretchr/testify/require"
)

func Teardown(t *testing.T, directory string, id string, keyPair *aws.Ec2Keypair) {
	repoRoot, err0 := GetRepoRoot(t)
	require.NoError(t, err0)
	err := os.RemoveAll(fmt.Sprintf("%s/examples/%s/.terraform", repoRoot, directory))
	require.NoError(t, err)
	err2 := os.RemoveAll(fmt.Sprintf("%s/examples/%s/rke2", repoRoot, directory))
	require.NoError(t, err2)
	err3 := os.RemoveAll(fmt.Sprintf("%s/examples/%s/tmp", repoRoot, directory))
	require.NoError(t, err3)
	err4 := os.RemoveAll(fmt.Sprintf("%s/examples/%s/.terraform.lock.hcl", repoRoot, directory))
	require.NoError(t, err4)
	err5 := os.RemoveAll(fmt.Sprintf("%s/examples/%s/terraform.tfstate", repoRoot, directory))
	require.NoError(t, err5)
	err6 := os.RemoveAll(fmt.Sprintf("%s/examples/%s/terraform.tfstate.backup", repoRoot, directory))
	require.NoError(t, err6)
	rm(t, fmt.Sprintf("%s/examples/%s/kubeconfig-*.yaml", repoRoot, directory))
	rm(t, fmt.Sprintf("%s/examples/%s/tf-*", repoRoot, directory))

	if id != "" {
		err7 := os.RemoveAll(filepath.Join(repoRoot, "test", "data", id))
		require.NoError(t, err7)
	}

	aws.DeleteEC2KeyPairContext(t, t.Context(), keyPair)
}

func rm(t *testing.T, path string) {
	files, err := filepath.Glob(path)
	require.NoError(t, err)
	for _, file := range files {
		err2 := os.RemoveAll(file)
		require.NoError(t, err2)
	}
}

func hasVariableDeclared(t *testing.T, directory, varName string) bool {
	repoRoot, err := GetRepoRoot(t)
	require.NoError(t, err)
	dirPath := filepath.Join(repoRoot, "examples", directory)

	tfFiles, err := filepath.Glob(filepath.Join(dirPath, "*.tf"))
	require.NoError(t, err)

	for _, file := range tfFiles {
		content, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		pattern := fmt.Sprintf(`variable "%s"`, varName)
		if strings.Contains(string(content), pattern) {
			return true
		}
	}
	return false
}

func Setup(t *testing.T, directory string, region string, owner string, id string, terraformVars map[string]any) (*terraform.Options, *aws.Ec2Keypair) {

	// Create an EC2 KeyPair that we can use for SSH access
	keyPairName := fmt.Sprintf("terraform-ci-%s", id)
	keyPair := aws.CreateAndImportEC2KeyPairContext(t, t.Context(), region, keyPairName)
	//log.Print(keyPair.KeyPair.PrivateKey)

	// tag the key pair so we can find in the access module
	client, err1 := aws.NewEc2ClientContextE(t, t.Context(), region)
	require.NoError(t, err1)

	input := &ec2.DescribeKeyPairsInput{
		KeyNames: []string{keyPairName},
	}
	result, err2 := client.DescribeKeyPairs(context.Background(), input)
	require.NoError(t, err2)

	aws.AddTagsToResourceContext(t, t.Context(), region, *result.KeyPairs[0].KeyPairId, map[string]string{"Name": keyPairName, "Owner": owner})

	repoRoot, err0 := GetRepoRoot(t)
	require.NoError(t, err0)

	// Ensure the test/data/${id} directory exists
	errMkdir := os.MkdirAll(filepath.Join(repoRoot, "test", "data", id), 0755)
	require.NoError(t, errMkdir)

	if hasVariableDeclared(t, directory, "key_name") {
		terraformVars["key_name"] = keyPairName
	}
	if hasVariableDeclared(t, directory, "key") {
		terraformVars["key"] = keyPair.PublicKey
	}
	if hasVariableDeclared(t, directory, "identifier") {
		terraformVars["identifier"] = id
	}
	if hasVariableDeclared(t, directory, "local_file_path") {
		terraformVars["local_file_path"] = filepath.Join(repoRoot, "test", "data", id)
	}

	retryableTerraformErrors := map[string]string{
		// The reason is unknown, but eventually these succeed after a few retries.
		".*unable to verify signature.*":             "Failed due to transient network error.",
		".*unable to verify checksum.*":              "Failed due to transient network error.",
		".*no provider exists with the given name.*": "Failed due to transient network error.",
		".*registry service is unreachable.*":        "Failed due to transient network error.",
		".*connection reset by peer.*":               "Failed due to transient network error.",
		".*TLS handshake timeout.*":                  "Failed due to transient network error.",
		".*i/o timeout.*":                            "Failed due to transient network error.",
		".*curl.*exit status 7.*":                    "Failed due to transient network error.",
	}
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: fmt.Sprintf("%s/examples/%s", repoRoot, directory),
		// Variables to pass to our Terraform code using -var options
		Vars: terraformVars,
		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
		RetryableTerraformErrors: retryableTerraformErrors,
		NoColor:                  true,
		MaxRetries:               20,
		Upgrade:                  true,
	})
	return terraformOptions, keyPair
}

func GetLatestRelease(t *testing.T, owner string, repo string) string {
	ghClient := github.NewClient(nil)
	release, _, err := ghClient.Repositories.GetLatestRelease(context.Background(), owner, repo)
	require.NoError(t, err)
	version := *release.TagName
	return version
}

func GetLatestCandidateRelease(t *testing.T, owner string, repo string) string {
	ghClient := github.NewClient(nil)
	releases, _, err := ghClient.Repositories.ListReleases(context.Background(), owner, repo, &github.ListOptions{Page: 1, PerPage: 1000})
	require.NoError(t, err)
	sort.Slice(releases, func(i, j int) bool {
		return releases[i].CreatedAt.GetTime().After(*releases[j].CreatedAt.GetTime())
	})

	sort.Slice(releases, func(i, j int) bool {
		v1, err2 := version.NewVersion(strings.SplitN(*releases[i].TagName, "+", 2)[0])
		require.NoError(t, err2)
		v2, err3 := version.NewVersion(strings.SplitN(*releases[j].TagName, "+", 2)[0])
		require.NoError(t, err3)
		return v1.GreaterThan(v2)
	})

	releaseTags := []string{}
	for i := range releases {
		if strings.Contains(*releases[i].TagName, "-rc") {
			releaseTags = append(releaseTags, *releases[i].TagName)
		}
	}
	return releaseTags[1]
}

func GetRepoRoot(t *testing.T) (string, error) {
	gwd := g.GetRepoRootContext(t, t.Context(), "")
	fwd, err := filepath.Abs(gwd)
	if err != nil {
		return "", fmt.Errorf("failed to get absolute path: %w", err)
	}
	return fwd, nil
}
