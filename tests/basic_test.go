package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestBasic(t *testing.T) {
	t.Parallel()
	directory := "basic"
	region := "us-west-1"
	owner := "terraform-ci@suse.com"
	terraformVars := map[string]interface{}{}
	terraformOptions, keyPair, sshAgent := setup(t, directory, region, owner, terraformVars)
	defer teardown(t, directory, keyPair, sshAgent)
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
