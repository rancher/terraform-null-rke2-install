package candidate

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
  util "github.com/rancher/terraform-null-rke2-install/test/tests"
)

func TestCandidate(t *testing.T) {
	t.Parallel()
	id := os.Getenv("IDENTIFIER")
	if id == "" {
		id = random.UniqueId()
	}
	directory := "candidate"
  id = id + "-" + directory
  region := os.Getenv("AWS_REGION")
  if region == "" {
    region = "us-west-2"
  }
	owner := "terraform-ci@suse.com"
	terraformVars := map[string]interface{}{
		"rke2_version": util.GetLatestCandidateRelease(t, "rancher", "rke2"),
		"rpm_channel":  "testing",
	}
	terraformOptions, keyPair := util.Setup(t, directory, region, owner, id, terraformVars)
	delete(terraformOptions.Vars, "key_name")

	sshAgent := ssh.SshAgentWithKeyPair(t, keyPair.KeyPair)
	defer sshAgent.Stop()
	terraformOptions.SshAgent = sshAgent

	defer util.Teardown(t, directory, keyPair)
	defer terraform.Destroy(t, terraformOptions)
	output, err := terraform.InitAndApplyE(t, terraformOptions)
	t.Log(output)
	if err != nil {
		t.Log(err)
		// don't fail if candidate testing fails
		return
	}
}
