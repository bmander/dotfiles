GITHUB_CONTAINER_REGISTRY_TOKEN=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

alias ??="gh copilot explain"
alias ?!="gh copilot suggest"

# set up gh copilot by erasing the codespaces-installed github token and prompting the user to log in using OAuth
alias ghlogin="gh auth login --web -h github.com -p https"
unset GITHUB_TOKEN
echo "Log into gh using 'ghlogin'"