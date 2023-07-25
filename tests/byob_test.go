package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestByob(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/byob",
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestByobConfigChange(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/byob",
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
	newConfig := "\"debug\": \"true\"\n\"node-label\":\n- \"foo=bar\"\n- \"something=amazing\"\n\"tls-san\":\n- \"foo.local\"\n\"write-kubeconfig-mode\": \"0644\"\n"
	n := []byte(newConfig)
	err := os.WriteFile("../examples/byob/rke2/rke2-config.yaml", n, 0600)
	require.NoError(t, err)
	// add a new config and apply changes
	terraform.Apply(t, terraformOptions)
	blankConfig := ""
	b := []byte(blankConfig)
	err = os.WriteFile("../examples/byob/rke2/rke2-config.yaml", b, 0600)
	require.NoError(t, err)
}
