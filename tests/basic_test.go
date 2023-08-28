package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestBasic(t *testing.T) {
	t.Parallel()
	directory := "basic"
	region := "us-west-1"
	owner := "terraform-ci@suse.com"
	terraformVars := map[string]interface{}{}
	terraformOptions, keyPair := setup(t, directory, region, owner, terraformVars)

	sshAgent := ssh.SshAgentWithKeyPair(t, keyPair.KeyPair)
	defer sshAgent.Stop()
	terraformOptions.SshAgent = sshAgent

	defer teardown(t, directory, keyPair)
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
