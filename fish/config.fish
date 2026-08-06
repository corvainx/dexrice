# Disable fish greeting
set -g fish_greeting

# Colors
set -U fish_color_param d4d4d4
set -U fish_color_command d4d4d4
set -U fish_color_valid_path d4d4d4

function starship_transient_prompt_func
    starship module character
end
function starship_transient_rprompt_func
    starship module custom.transient_time
end
starship init fish | source

# eza aliases
alias l="eza --icons"
alias ll="eza -la --icons --git"
alias lll="eza -lah --icons --git"
alias lt="eza --tree --icons"

alias reload="source ~/.config/fish/config.fish"
alias matrix='unimatrix -s 95'
alias ll='ls -a'
alias yt='ytfzf'
alias ytm='ytfzf -m'
alias v='nvim'
alias ff='fastfetch'
alias os='cat /etc/os-release'
alias sessiontype='echo $XDG_SESSION_TYPE'
alias vel='nvim ~/veluna/src-tauri/packaging/postinst.sh'
alias agy='~/Antigravity-x64/antigravity'
alias dev='npm run tauri dev'
alias build='npm run tauri build'
alias cdv='cd ~/veluna/'
alias cdf='cd ~/fedora-configs/'
alias cdn='cd ~/networking-from-scratch/'
alias cdp='cd ~/python-notes/'
alias cdb='cd ~/bash-scripting-YSAP/'
alias dotv='cd ~/.config/nvim/'
alias vt='nvim ~/.config/tmux/tmux.conf'
alias dott='cd ~/.config/tmux/'
alias vk='nvim ~/.config/kitty/kitty.conf'
alias dotk='cd ~/.config/kitty/'
