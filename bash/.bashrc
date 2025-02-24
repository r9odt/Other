# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

RED="\033[0;31m"
REDB="\033[1;31m"
GRE="\033[0;32m"
YEL="\033[0;33m"
BLU="\033[0;34m"
LBL="\033[0;36m"
DEF="\033[0;00m"
DEFI="\033[3;37m"

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000
HISTFILE=~/.bash_history
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color|screen*) color_prompt=yes;;
    xterm) color_prompt=no;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1="[\u@\h \A \[${DEFI}\]\W\[${DEF}\] ] \[${REDB}\]\$(parse_git_branch)\[${DEF}\]\$ "
else
    PS1="[\u@\h \W] \$(parse_git_branch)\$ "
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
  xterm);;
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

if [ ! -z ${MC_TMPDIR} ]; then
  if [ "$color_prompt" = yes ]; then
    PS1="\[${REDB}\](mc) \[${DEF}\]${PS1}"
  else
    PS1="(mc) ${PS1}"
  fi
fi

export PS1

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

parse_git_branch() {
    git_branch=$(git branch 2>/dev/null | sed -n '/^\*/s/^\* //p')
    if [[ $git_branch ]]; then
    echo "[$git_branch] "
    else
    echo ""
    fi
}

alias l='ls -lahX'
alias sbash='source ~/.bashrc'
alias disp='export DISPLAY=:0'
alias path='echo -e ${PATH//:/\\n}'
alias cssh='wrap_ssh(){ ssh $*; printf "\n[$(date)] : Disconnect.\n";  unset -f wrap_ssh; }; wrap_ssh'

export HISTTIMEFORMAT="%d/%m/%y %T "
export PROMPT_COMMAND='printf "%%%$((COLUMNS-1))s\\r"'
# wrap_alias takes three arguments:
# $1: The name of the alias
# $2: The command used in the alias
# $3: The arguments in the alias all in one string
# Generate a wrapper completion function (completer) for an alias
# based on the command and the given arguments, if there is a
# completer for the command, and set the wrapper as the completer for
# the alias.
function wrap_alias() {
  [[ "$#" == 3 ]] || return 1

  local alias_name="$1"
  local aliased_command="$2"
  local alias_arguments="$3"
  local num_alias_arguments=$(echo "$alias_arguments" | wc -w)

  # The completion currently being used for the aliased command.
  local completion=$(complete -p $aliased_command 2> /dev/null)

  # Only a completer based on a function can be wrapped so look for -F
  # in the current completion. This check will also catch commands
  # with no completer for which $completion will be empty.
  echo $completion | grep -q -- -F || return 0

  local namespace=alias_completion::

  # Extract the name of the completion function from a string that
  # looks like: something -F function_name something
  # First strip the beginning of the string up to the function name by
  # removing "* -F " from the front.
  local completion_function=${completion##* -F }
  # Then strip " *" from the end, leaving only the function name.
  completion_function=${completion_function%% *}

  # Try to prevent an infinite loop by not wrapping a function
  # generated by this function. This can happen when the user runs
  # this twice for an alias like ls='ls --color=auto' or alias l='ls'
  # and alias ls='l foo'
  [[ "${completion_function#$namespace}" != $completion_function ]] && return 0

  local wrapper_name="${namespace}${alias_name}"

  eval "
function ${wrapper_name}() {
  let COMP_CWORD+=$num_alias_arguments
  args=( \"${alias_arguments}\" )
  COMP_WORDS=( $aliased_command \${args[@]} \${COMP_WORDS[@]:1} )
  $completion_function
  }
"

  # To create the new completion we use the old one with two
  # replacements:
  # 1) Replace the function with the wrapper.
  local new_completion=${completion/-F * /-F $wrapper_name }
  # 2) Replace the command being completed with the alias.
  new_completion="${new_completion% *} $alias_name"

  eval "$new_completion"
}

# For each defined alias, extract the necessary elements and use them
# to call wrap_alias.
#eval "$(alias -p | grep ${WRAP_ALIAS_FOR?} | sed -e 's/alias \([^=][^=]*\)='\''\([^ ][^ ]*\) *\(.*\)'\''/wrap_alias \1 \2 '\''\3'\'' /')"

# User specific aliases and functions
if [ -d ${HOME}/.bashrc.d ]; then
        for rc in ${HOME}/.bashrc.d/*.sh; do
                if [ -f "$rc" ]; then
                        . "$rc"
                fi
        done
fi

unset rc
