# GitHub Copilot Review Instructions

When performing a code review or suggesting changes, adhere strictly to the following guidelines to prevent iterative "drip-feed" reviews and noisy feedback:

## Single-Pass Comprehensive Review
- **No Drip-Feeding:** You MUST provide ALL of your feedback in a single, comprehensive review. Do not hold back comments for future interactions.
- Analyze the entire pull request and consolidate every single finding into your initial response.

## Focus Exclusively on Functionality-Blocking Issues
- **Security:** Highlight potential vulnerabilities, exposed secrets, or unsafe data handling.
- **Bugs & Logic Errors:** Point out broken logic, unhandled edge cases, nil pointer dereferences, or potential race conditions.
- **Performance:** Identify significant bottlenecks, severe memory leaks, or highly inefficient resource usage.
- **Architecture:** Flag major architectural flaws or severe violations of core design principles that will drastically harm maintainability.

## Avoid Bikeshedding (Trivial Suggestions)
- Do **not** suggest changes that minimally affect the functionality of the code.
- Ignore subjective styling, variable naming (unless dangerously misleading), and minor formatting adjustments.
- Do not recommend alternative language syntax or minor refactors if the current implementation is functional and readable.
- **Crucial:** If a suggestion does not prevent a critical bug, fix a vulnerability, or address a functionality-blocking issue, you MUST omit it.

## Review Format
- Provide actionable, concrete feedback ONLY for the critical, blocking issues identified.
- If the pull request has no critical or highly important issues, explicitly state that the code looks good and approve the review. 
- Resist the urge to leave comments just for the sake of leaving comments. If in doubt about whether an issue blocks functionality, DO NOT comment.
