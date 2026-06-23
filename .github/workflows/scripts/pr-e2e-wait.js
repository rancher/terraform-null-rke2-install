export default async ({ github, context }) => {
  const { owner, repo } = context.repo;
  const issue_number = context.issue.number || context.payload.pull_request?.number;
  const runUrl = `${context.serverUrl}/${owner}/${repo}/actions/runs/${context.runId}`;

  await github.rest.issues.createComment({
    owner,
    repo,
    issue_number,
    body: `**E2E Tests Running...** Please wait while the end-to-end tests complete execution.\n\n[View test run](${runUrl})`
  });
};
