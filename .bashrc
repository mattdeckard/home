# .bashrc

# User specific aliases and functions

# Basic stuff
export PAGER=less
export EDITOR=vim
export LC_COLLATE="C" # changes way files are ordered

# Add entries to path, only if they don't exist yet
_back_path () {
   export PATH=$PATH:$1
}
_front_path () {
   export PATH=$1:$PATH
}
back_path () {
   [ -z $(echo $PATH | grep "^$1:\|:$1:\|:$1\$") ] && _back_path "$1"
}
front_path () {
   [ -z $(echo $PATH | grep "^$1:\|:$1:\|:$1\$") ] && _front_path "$1"
}

# strip /usr/local/sbin out of PATH
export PATH=${PATH/:\/usr\/local\/sbin/}

front_path $HOME/bin

# default umask
export UMASK_DEFAULT=0022
umask $UMASK_DEFAULT

# less settings (mostly for man pages)
export LESS_TERMCAP_mb=$'\E[01;31m' # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m' # begin bold
export LESS_TERMCAP_me=$'\E[0m' # end mode
export LESS_TERMCAP_se=$'\E[0m' # end standout-mode
export LESS_TERMCAP_so=$'\E[38;5;246m' # begin standout-mode - info box 
export LESS_TERMCAP_ue=$'\E[0m' # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

###########
# aliases #
###########
. ~/.bashrc_aliases

#############
# functions #
#############

#
# prints smiley on prompt to indicate success/fail of last cmd
#
smileyc () {
  STAT=$?
  if [ $STAT = 0 ]; then
    echo -e '\e[32m'
  else
    echo -e '\e[0m'
  fi
  return $STAT
}
smiley () {
  STAT=$?
  #DEBUG:
  if [ $1 ]
  then
    STAT="$1"
  fi

  if [ $STAT = 0 ]; then
    echo ":-)"
  else
    # error status
    # default is to display numerical status
    # but for certain ones, we display the "special meaning"
    SDISP=`printf "%03d" "$STAT"`
    case "$STAT" in
      125) SDISP="SVR" ;;
      126) SDISP="NOEX" ;;
      127) SDISP="NOCMD" ;;
      128) SDISP=" -1" ;;
      129) SDISP="FATAL1" ;;
      130) SDISP="FATAL2" ;;
      131) SDISP="QUIT" ;;
      132) SDISP="ILL" ;;
      133) SDISP="TRAP" ;;
      134) SDISP="ABORT" ;;
      135) SDISP="BUS" ;;
      136) SDISP="FPE" ;;
      137) SDISP="KILL" ;;
      139) SDISP="SEG"; asdf ;;
      141) SDISP="PIPE" ;;
      142) SDISP="ALRM" ;;
      143) SDISP="TERM" ;;
      148) SDISP="STP" ;;
      152) SDISP="XCPU" ;;
      159) SDISP="SYS" ;;
    esac
    echo "$SDISP"
  fi
  return $STAT
}

export GROUP_DEFAULT=1024
#
# prints current group on prompt, if it is not default
#
psgroup() {
   local group=$(id -g)
   [ "$group" -ne "$GROUP_DEFAULT" ] && echo -n "[g:$group]"
}

#
# prints current group on prompt, if it is not default
#
psumask() {
   local umask=$(umask)
   [ "$umask" -ne "$UMASK_DEFAULT" ] && echo -n "[u:$umask]"
}

#
# set title to something static
#
title() {
   export TITLE="$1"
}

#
# sets title of screen shell dynamically
#
screen_title() {
   if [ "$1" = "debug" ]
   then
      ECHOCMD="echo -n"
   else
      ECHOCMD="echo -ne"
   fi

   if [ "$TITLE" ]
   then
      $ECHOCMD "\ek${TITLE}\e\\"
      return
   fi

   # get a nice CWD
   CWD=${PWD##*/}
   if [ "$PWD" = ~ ]
   then
      # if we're in home, set title to "~"
      CWD="~"
   elif [ "$CWD" = "src" -o "$CWD" = "lib" -o "$CWD" = "test" -o "$CWD" = "bin" ]
   then
      # append parent directory
      CWD=`echo $PWD | awk -F/ '{printf "%s/%s", $(NF-1), $NF}'`
      true
   fi

   if [ "$SSH_TTY" ] && [ ! "$STY" ]
   then
      # we are in non-screen SSH session, set title to hostname
      $ECHOCMD "\ek${CWD}@${HOSTNAME%%.*}\e\\"
      return
   fi

   # default, echo basename of CWD
   $ECHOCMD "\ek${CWD}\e\\"
}

##########
# prompt #
##########
yellow='\[\e[33m\]'
red='\[\e[31m\]'
magenta='\[\e[35m\]'
# set prompt to magenta if in non-screen ssh
if [ "$SSH_TTY" ] && [ ! "$STY" ]
then
   pscolor=$magenta
   psalt=$red
else
   pscolor=$red
   psalt=$magenta
fi

# if this is an interactive shell, set PS1 to something decent
if [ "$PS1" ]; then

   if declare -f __git_ps1 >/dev/null; then
      GIT_PS1='$(__git_ps1 "[%s]")'
   fi

   # my default red prompt
   PS1=
   #PS1="$PS1"'\[\ek\e\\\]'                      # <esc>k<esc> for screen's dynamic prompt feature
   PS1="$PS1$pscolor"                            # pscolor
   PS1="$PS1"'[\j]'                              # jobs
   PS1="$PS1"'[\[`smileyc`\]'                    # [ GREEN | GREY
   PS1="$PS1"'`smiley`'                          # :) | :(
   PS1="$PS1$pscolor"']'                         # pscolor ]
   PS1="$PS1$psalt"                              # psalt
   PS1="$PS1"'`psgroup`'                         # [group] (if not default)
   PS1="$PS1"'`psumask`'                         # [umask] (if not default)
   PS1="$PS1$pscolor"                            # pscolor
   PS1="$PS1$yellow$GIT_PS1$pscolor"             # [GIT_BRANCH]
   PS1="$PS1"'\u@\h:\W \$'                       # user@host:dir $
   PS1="$PS1"'\[\e[0m\] '                        # GREY

  case $TERM in
    xterm*)
      PS1="$PS1"'\[\033]0;`'
      PS1="$PS1"'echo "$HOSTNAME" | tr "[:upper:]" "[:lower:]"'
      PS1="$PS1"'` \w\007\]'
      ;;
    screen)
      # title-escape-sequence for screen's dynamic title feature
      PS1="$PS1"'\[`screen_title`\]'
      #PROMPT_COMMAND='screen_title'
      ;;
  esac

  # Note: Do not export PS1.  It is just for this shell, not its children.

  # also only set these if interactive shell
  bind '"\e[A"':history-search-backward
  bind '"\e[B"':history-search-forward
  shopt -s cdspell  # sloppy dir spelling for cd
  shopt -s dirspell # sloppy dir spelling for tab completion

fi
