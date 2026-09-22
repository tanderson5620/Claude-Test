# Git hooks

`pre-commit` scans staged changes for credentials and aborts the commit when it
finds one. It names the file and line but never prints the secret itself.

It is active in this clone because the repository sets:

    git config core.hooksPath .githooks

A fresh clone needs that line run once — hooks are not installed by git
automatically, which is why the config lives in the repository rather than in
`.git/hooks`.

## What it catches

Key shapes for AWS, GitHub, OpenAI, Anthropic, Google, Slack, Stripe, Twilio
and SendGrid; private key blocks; JSON web tokens; bare 64-character hex blobs
(the shape of a SerpAPI key); anything assigned to a name like `api_key`,
`secret`, `password` or `access_token`; and files whose names are credentials
in themselves — `.env`, `id_rsa`, `*.pem`, `credentials.json` and friends.

Placeholders are allowed through, so `YOUR_API_KEY`, `PASTE_YOUR_KEY_HERE` and
`$SERPAPI_KEY` do not trip it.

## If it fires

Remove the value and read it from the environment instead. If the key was ever
pushed, **rotate it** — deleting the commit does not remove it from the history,
and scanners read public commits within seconds of a push.

`git commit --no-verify` skips the hook. That is the one thing standing between
a key and a public repository, so use it only when you are certain.
