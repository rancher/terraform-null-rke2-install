package test

import (
	"context"
	"fmt"
	"os"
	"testing"

	"github.com/google/go-github/v53/github"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/hashicorp/go-getter"
	"github.com/stretchr/testify/require"
)

func TestByobConfigChange(t *testing.T) {
	t.Parallel()
	directory := "byob"
	region := "us-west-1"
	owner := "terraform-ci@suse.com"
	download_path := fmt.Sprintf("../examples/%s/rke2", directory)
	err1 := os.Mkdir(download_path, 0755)
	require.NoError(t, err1)

	ghClient := github.NewClient(nil)
	release, _, err2 := ghClient.Repositories.GetLatestRelease(context.Background(), "rancher", "rke2")
	require.NoError(t, err2)
	version := *release.TagName

	terraformVars := map[string]interface{}{
		"release": version,
	}
	terraformOptions, keyPair, sshAgent := setup(t, directory, region, owner, terraformVars)
	defer teardown(t, directory, keyPair, sshAgent)

	url := fmt.Sprintf("https://github.com/rancher/rke2/releases/download/%s", version)

	err3 := os.WriteFile(fmt.Sprintf("%s/rke2-config.yaml", download_path), []byte(""), 0600)
	require.NoError(t, err3)

	// download rke2 binary, images, sha256sum, and install script
	err4 := getter.GetAny(download_path, fmt.Sprintf("%s/rke2.linux-amd64.tar.gz?archive=false", url))
	require.NoError(t, err4)
	err5 := getter.GetAny(download_path, fmt.Sprintf("%s/rke2-images.linux-amd64.tar.gz?archive=false", url))
	require.NoError(t, err5)
	err6 := getter.GetAny(download_path, fmt.Sprintf("%s/sha256sum-amd64.txt", url))
	require.NoError(t, err6)
	err7 := getter.GetAny(download_path, "https://raw.githubusercontent.com/rancher/rke2/master/install.sh")
	require.NoError(t, err7)

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// change config
	newConfig := "\"debug\": \"true\"\n\"node-label\":\n- \"foo=bar\"\n- \"something=amazing\"\n\"tls-san\":\n- \"foo.local\"\n\"write-kubeconfig-mode\": \"0644\"\n"
	err8 := os.WriteFile(fmt.Sprintf("%s/rke2-config.yaml", download_path), []byte(newConfig), 0600)
	require.NoError(t, err8)

	// apply again to test config change, this should only copy the config over and not re-install rke2
	terraform.Apply(t, terraformOptions)
}
