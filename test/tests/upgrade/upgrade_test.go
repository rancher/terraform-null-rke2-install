package upgrade

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"

	util "github.com/rancher/terraform-null-rke2-install/test/tests"
	"github.com/stretchr/testify/assert"
)

func TestUpgrade(t *testing.T) {
	t.Parallel()
	id := os.Getenv("IDENTIFIER")
	if id == "" {
		id = random.UniqueId()
	}
	directory := "upgrade"
	id = id + "-" + directory
	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = "us-west-2"
	}
	owner := "terraform-ci@suse.com"

	// Initial version to deploy
	initialVersion := "v1.34.6+rke2r3"
	// Upgraded version
	upgradeVersion := "v1.35.3+rke2r3"

	terraformVars := map[string]interface{}{
		"rke2_version": initialVersion,
	}
	terraformOptions, keyPair := util.Setup(t, directory, region, owner, id, terraformVars)

	sshAgent := ssh.SshAgentWithKeyPair(t, keyPair.KeyPair)
	defer sshAgent.Stop()
	terraformOptions.SshAgent = sshAgent

	defer util.Teardown(t, directory, keyPair)
	defer terraform.Destroy(t, terraformOptions)

	// Initial deployment
	t.Logf("Deploying initial RKE2 version: %s", initialVersion)
	terraform.InitAndApply(t, terraformOptions)

	// Verify initial deployment
	out := terraform.OutputAll(t, terraformOptions)
	t.Logf("Initial deployment output: %v", out)
	outputServer, ok := out["server"].(map[string]interface{})
	assert.True(t, ok, fmt.Sprintf("Wrong data type for 'server', expected map[string], got %T", out["server"]))
	outputKubeconfig, ok := out["kubeconfig"].(string)
	assert.True(t, ok, fmt.Sprintf("Wrong data type for 'kubeconfig', expected string, got %T", out["kubeconfig"]))
	outputVersion, ok := out["rke2_version"].(string)
	assert.True(t, ok, fmt.Sprintf("Wrong data type for 'rke2_version', expected string, got %T", out["rke2_version"]))

	assert.NotEmpty(t, outputKubeconfig, "The 'kubeconfig' is empty")
	assert.NotEmpty(t, outputServer["public_ip"], "The 'server.public_ip' is empty")
	assert.Equal(t, initialVersion, outputVersion, "Initial version mismatch")

	// Perform upgrade
	t.Logf("Upgrading RKE2 from %s to %s", initialVersion, upgradeVersion)
	terraformOptions.Vars["rke2_version"] = upgradeVersion
	terraform.Apply(t, terraformOptions)

	// Verify upgrade
	outUpgrade := terraform.OutputAll(t, terraformOptions)
	t.Logf("Upgrade output: %v", outUpgrade)
	outputVersionUpgrade, ok := outUpgrade["rke2_version"].(string)
	assert.True(t, ok, fmt.Sprintf("Wrong data type for 'rke2_version', expected string, got %T", outUpgrade["rke2_version"]))
	outputKubeconfigUpgrade, ok := outUpgrade["kubeconfig"].(string)
	assert.True(t, ok, fmt.Sprintf("Wrong data type for 'kubeconfig', expected string, got %T", outUpgrade["kubeconfig"]))

	assert.Equal(t, upgradeVersion, outputVersionUpgrade, "Upgrade version mismatch")
	assert.NotEmpty(t, outputKubeconfigUpgrade, "The 'kubeconfig' is empty after upgrade")

	t.Logf("Successfully upgraded from %s to %s", initialVersion, upgradeVersion)
}
