export default async ({ github, context }) => {
  const { owner, repo } = context.repo;
  const issue_number = context.issue.number || context.payload.pull_request?.number;

  await github.rest.issues.createComment({
    owner,
    repo,
    issue_number,
    body: `**E2E Tests Passed!** The infrastructure tests have completed successfully.`
  });
};
