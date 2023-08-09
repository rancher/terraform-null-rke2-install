package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestBasic(t *testing.T) {
	t.Parallel()
	defer basicTeardown(t)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
		Upgrade:      true,
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func basicTeardown(t *testing.T) {
	err := os.RemoveAll("../examples/basic/.terraform")
	require.NoError(t, err)
	err1 := os.RemoveAll("../examples/basic/rke2")
	require.NoError(t, err1)
}
