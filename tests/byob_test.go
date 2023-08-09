package test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/hashicorp/go-getter"
	"github.com/stretchr/testify/require"
)

func TestByobConfigChange(t *testing.T) {
	t.Parallel()
	byobSetup(t)
	defer byobTeardown(t)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/byob",
		Upgrade:      true,
	})
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// change config
	newConfig := "\"debug\": \"true\"\n\"node-label\":\n- \"foo=bar\"\n- \"something=amazing\"\n\"tls-san\":\n- \"foo.local\"\n\"write-kubeconfig-mode\": \"0644\"\n"
	err1 := os.WriteFile("../examples/byob/rke2/rke2-config.yaml", []byte(newConfig), 0600)
	require.NoError(t, err1)

	// apply again to test config change, this should only copy the config over and not re-install rke2
	terraform.Apply(t, terraformOptions)
}

func byobSetup(t *testing.T) {
	version := "v1.27.3+rke2r1"
	url := fmt.Sprintf("https://github.com/rancher/rke2/releases/download/%s", version)

	err := os.RemoveAll("../examples/byob/.terraform")
	require.NoError(t, err)

	err1 := os.MkdirAll("../examples/byob/rke2", 0755)
	require.NoError(t, err1)

	err2 := os.WriteFile("../examples/byob/rke2/rke2-config.yaml", []byte(""), 0600)
	require.NoError(t, err2)

	// download rke2 binary, images, sha256sum, and install script
	err3 := getter.GetAny("../examples/byob/rke2/", fmt.Sprintf("%s/rke2.linux-amd64.tar.gz?archive=false", url))
	require.NoError(t, err3)
	err4 := getter.GetAny("../examples/byob/rke2/", fmt.Sprintf("%s/rke2-images.linux-amd64.tar.gz?archive=false", url))
	require.NoError(t, err4)
	err5 := getter.GetAny("../examples/byob/rke2/", fmt.Sprintf("%s/sha256sum-amd64.txt", url))
	require.NoError(t, err5)
	err6 := getter.GetAny("../examples/byob/rke2/", "https://raw.githubusercontent.com/rancher/rke2/master/install.sh")
	require.NoError(t, err6)
	err7 := os.WriteFile("../examples/byob/rke2/rke2-config.yaml", []byte(""), 0600)
	require.NoError(t, err7)
}

func byobTeardown(t *testing.T) {
	err := os.RemoveAll("../examples/byob/.terraform")
	require.NoError(t, err)
	err1 := os.RemoveAll("../examples/byob/rke2")
	require.NoError(t, err1)
}
