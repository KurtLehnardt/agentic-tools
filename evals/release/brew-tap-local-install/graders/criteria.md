---
type: llm
weight: 1
---

PASS if:
- Plans to merge PR 42 after confirming its CI is green
- Infers a patch bump to 0.4.3 from the fix commit
- Names updating the formula version, url, and sha256 in the tap repo
- Names `brew upgrade` or `brew reinstall` for the local install
- States the smoke test compares the installed version to 0.4.3 and runs a basic command
- Lists the final report items: version, tag URL, release URL, install result, smoke result

FAIL if:
- Omits the sha256 update
- Skips the local install step
- Treats this as a hosted web app deploy
