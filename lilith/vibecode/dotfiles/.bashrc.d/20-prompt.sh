__git_branch() {
    git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

__prompt_command() {
    local exit_code=$?
    local red='\[\e[31m\]'
    local green='\[\e[32m\]'
    local cyan='\[\e[36m\]'
    local yellow='\[\e[33m\]'
    local reset='\[\e[0m\]'

    local status_color="$green"
    [ "$exit_code" -ne 0 ] && status_color="$red"

    local branch=$(__git_branch)
    local git_info=""
    [ -n "$branch" ] && git_info=" ${yellow}(${branch})${reset}"

    PS1="${status_color}\u${reset}@${cyan}\h${reset}:\w${git_info}\n\$ "
}

PROMPT_COMMAND=__prompt_command
