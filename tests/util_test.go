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

	a "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/google/go-github/v53/github"
	aws "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/hashicorp/go-version"
	"github.com/stretchr/testify/require"
)

func teardown(t *testing.T, directory string, keyPair *aws.Ec2Keypair) {
	err := os.RemoveAll(fmt.Sprintf("../examples/%s/.terraform", directory))
	require.NoError(t, err)
	err2 := os.RemoveAll(fmt.Sprintf("../examples/%s/rke2", directory))
	require.NoError(t, err2)
	err3 := os.RemoveAll(fmt.Sprintf("../examples/%s/tmp", directory))
	require.NoError(t, err3)
	err4 := os.RemoveAll(fmt.Sprintf("../examples/%s/.terraform.lock.hcl", directory))
	require.NoError(t, err4)
	err5 := os.RemoveAll(fmt.Sprintf("../examples/%s/terraform.tfstate", directory))
	require.NoError(t, err5)
	err6 := os.RemoveAll(fmt.Sprintf("../examples/%s/terraform.tfstate.backup", directory))
	require.NoError(t, err6)
	rm(t, fmt.Sprintf("../examples/%s/kubeconfig-*.yaml", directory))
	rm(t, fmt.Sprintf("../examples/%s/tf-*", directory))

	aws.DeleteEC2KeyPair(t, keyPair)
}

func rm(t *testing.T, path string) {
	files, err := filepath.Glob(path)
	require.NoError(t, err)
	for _, file := range files {
		err2 := os.RemoveAll(file)
		require.NoError(t, err2)
	}
}

func setup(t *testing.T, directory string, region string, owner string, id string, terraformVars map[string]interface{}) (*terraform.Options, *aws.Ec2Keypair) {

	// Create an EC2 KeyPair that we can use for SSH access
	keyPairName := fmt.Sprintf("terraform-aws-server-test-%s-%s", directory, id)
	keyPair := aws.CreateAndImportEC2KeyPair(t, region, keyPairName)
	//log.Print(keyPair.KeyPair.PrivateKey)

	// tag the key pair so we can find in the access module
	client, err1 := aws.NewEc2ClientE(t, region)
	require.NoError(t, err1)

	input := &ec2.DescribeKeyPairsInput{
		KeyNames: []*string{a.String(keyPairName)},
	}
	result, err2 := client.DescribeKeyPairs(input)
	require.NoError(t, err2)

	aws.AddTagsToResource(t, region, *result.KeyPairs[0].KeyPairId, map[string]string{"Name": keyPairName, "Owner": owner})

	terraformVars["key_name"] = keyPairName
	terraformVars["key"] = keyPair.KeyPair.PublicKey
	terraformVars["identifier"] = id

	retryableTerraformErrors := map[string]string{
		// The reason is unknown, but eventually these succeed after a few retries.
		".*unable to verify signature.*":             "Failed due to transient network error.",
		".*unable to verify checksum.*":              "Failed due to transient network error.",
		".*no provider exists with the given name.*": "Failed due to transient network error.",
		".*registry service is unreachable.*":        "Failed due to transient network error.",
		".*connection reset by peer.*":               "Failed due to transient network error.",
		".*TLS handshake timeout.*":                  "Failed due to transient network error.",
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: fmt.Sprintf("../examples/%s", directory),
		// Variables to pass to our Terraform code using -var options
		Vars: terraformVars,
		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
		RetryableTerraformErrors: retryableTerraformErrors,
	})
	return terraformOptions, keyPair
}

func getLatestRelease(t *testing.T, owner string, repo string) string {
	ghClient := github.NewClient(nil)
	release, _, err := ghClient.Repositories.GetLatestRelease(context.Background(), owner, repo)
	require.NoError(t, err)
	version := *release.TagName
	return version
}

func getLatestCandidateRelease(t *testing.T, owner string, repo string) string {
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
