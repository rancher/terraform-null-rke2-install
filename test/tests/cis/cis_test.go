package cis

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
  util "github.com/rancher/terraform-null-rke2-install/test/tests"
)

func TestCis(t *testing.T) {
	t.Parallel()
	id := os.Getenv("IDENTIFIER")
	if id == "" {
		id = random.UniqueId()
	}
	directory := "cis"
  id = id + "-" + directory
  region := os.Getenv("AWS_REGION")
  if region == "" {
    region = "us-west-2"
  }
	owner := "terraform-ci@suse.com"
	release := "stable"
  zone := os.Getenv("ZONE")
	terraformVars := map[string]interface{}{
		"rke2_version": release,
    "zone": zone,
	}
	terraformOptions, keyPair := util.Setup(t, directory, region, owner, id, terraformVars)

	sshAgent := ssh.SshAgentWithKeyPair(t, keyPair.KeyPair)
	defer sshAgent.Stop()
	terraformOptions.SshAgent = sshAgent

	defer util.Teardown(t, directory, keyPair)
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
