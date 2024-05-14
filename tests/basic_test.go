package test

import (
	"os"
	"testing"
	"encoding/json"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"

	"github.com/stretchr/testify/assert"
)

func TestBasic(t *testing.T) {
	t.Parallel()
	id := os.Getenv("IDENTIFIER")
	if id == "" {
		id = random.UniqueId()
	}
	directory := "basic"
	region := "us-west-1"
	owner := "terraform-ci@suse.com"
	release := "stable"
	terraformVars := map[string]interface{}{
		"rke2_version": release,
	}
	terraformOptions, keyPair := setup(t, directory, region, owner, id, terraformVars)

	sshAgent := ssh.SshAgentWithKeyPair(t, keyPair.KeyPair)
	defer sshAgent.Stop()
	terraformOptions.SshAgent = sshAgent

	defer teardown(t, directory, keyPair)
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	outputJson := terraform.OutputJson(t, terraformOptions, "")
	type OutputData struct {
		Kubeconfig struct {
			Sensitive bool   `json:"sensitive"`
			Type      string `json:"type"`
			Value     string `json:"value"`
		} `json:"kubeconfig"`
	}
	var data OutputData
	t.Logf("Json Output: %s", outputJson)
	err := json.Unmarshal([]byte(outputJson), &data)
	if err != nil {
		t.Fatalf("Error unmarshalling Json: %v", err)
	}
	assert.NotEmpty(t, data.Kubeconfig.Value)
	assert.NotEqualValues(t, data.Kubeconfig.Value, "not found")
}
