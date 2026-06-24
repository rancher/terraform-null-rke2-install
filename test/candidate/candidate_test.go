package candidate

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	util "github.com/rancher/terraform-null-rke2-install/test"
)

func TestCandidate(t *testing.T) {
	t.Parallel()
	id := os.Getenv("IDENTIFIER")
	if id == "" {
		id = random.UniqueID()
	}
	directory := "candidate"
	id = id + "-" + directory
	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = "us-west-2"
	}
	owner := "terraform-ci@suse.com"
	terraformVars := map[string]any{
		"rke2_version": util.GetLatestCandidateRelease(t, "rancher", "rke2"),
		"rpm_channel":  "testing",
	}
	terraformOptions, keyPair := util.Setup(t, directory, region, owner, id, terraformVars)
	delete(terraformOptions.Vars, "key_name")

	sshAgent := ssh.SSHAgentWithKeyPair(t, t.Context(), keyPair.KeyPair)
	defer sshAgent.Stop()
	terraformOptions.SshAgent = sshAgent

	defer util.Teardown(t, directory, keyPair)
	defer terraform.DestroyContext(t, t.Context(), terraformOptions)
	output, err := terraform.InitAndApplyContextE(t, t.Context(), terraformOptions)
	t.Log(output)
	if err != nil {
		// Mark test as failed but allow cleanup to run
		t.Errorf("Candidate test failed (this may be expected if the release candidate has issues): %v", err)
	}
}
