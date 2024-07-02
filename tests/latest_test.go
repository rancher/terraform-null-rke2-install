package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestLatest(t *testing.T) {
	t.Parallel()
	id := os.Getenv("IDENTIFIER")
	if id == "" {
		id = random.UniqueId()
	}
	directory := "latest"
	region := "us-west-1"
	owner := "terraform-ci@suse.com"
	terraformVars := map[string]interface{}{}
	terraformOptions, keyPair := setup(t, directory, region, owner, id, terraformVars)

	sshAgent := ssh.SshAgentWithKeyPair(t, keyPair.KeyPair)
	defer sshAgent.Stop()
	terraformOptions.SshAgent = sshAgent

	defer teardown(t, directory, keyPair)
	defer terraform.Destroy(t, terraformOptions)
	output, err := terraform.InitAndApplyE(t, terraformOptions)
	t.Log(output)
	if err != nil {
		t.Log(err)
		// don't fail if latest fails
		// generally this fails when a release is newly out because rpms have not had time to propagate
		return
	}
}
