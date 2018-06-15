#!/bin/sh
#
# Copyright (c) 2018 Alejandro Liu
# Licensed under the MIT license:
#
# Permission is  hereby granted,  free of charge,  to any  person obtaining
# a  copy  of  this  software   and  associated  documentation  files  (the
# "Software"),  to  deal in  the  Software  without restriction,  including
# without  limitation the  rights  to use,  copy,  modify, merge,  publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons  to whom  the Software  is  furnished to  do so,  subject to  the
# following conditions:
#
# The above copyright  notice and this permission notice  shall be included
# in all copies or substantial portions of the Software.
#
# THE  SOFTWARE  IS  PROVIDED  "AS  IS",  WITHOUT  WARRANTY  OF  ANY  KIND,
# EXPRESS  OR IMPLIED,  INCLUDING  BUT  NOT LIMITED  TO  THE WARRANTIES  OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR  OTHER LIABILITY, WHETHER  IN AN  ACTION OF CONTRACT,  TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
set -euf -o pipefail

_strip_hash_comments() {
  ## Remove '#' comments from stream
  ## # USAGE
  ##	_strip_hash_comments < in > out
  ## # DESC
  ## Filter to remove comments
  sed \
    -e 's/^\s*#.*$//' \
    -e 's/^\s*//' -e 's/\s*$//'
}

_split_cfg_line() {
  ## Split configuration line
  ## # USAGE
  ##	split_cfg_line "$line" [left_val [right_val]]
  ## # DESC
  ## Looks for the separator ":" and assigns to "left_val"
  ## and "right_val" variables.  Note, that these should have
  ## been declared as local.
  ##
  ## Parsing will handle "\", quote and double-quotes.
  ## 
  ## Returns "true" if ":" is found, otherwise returns "false"
  ##
  local ln="$1"
  local i=1 j='' k=$(expr length "$ln")

  while [ $i -le $k ]
  do
    ch=$(expr substr "$ln" $i 1)
    if [ -z "$j" ] ; then
      # We are looking for the ":" separator...
      case "$ch" in
      :)
	# WE FOUND IT!
	local _left="$(expr substr "$ln" 1 $(expr $i - 1) | sed -e 's/\s*$//')"
	local _right=""
	[ $i -lt $k ] && _right="$(expr substr "$ln" $(expr $i + 1) $(expr $k - $i) | sed -e 's/^\s*//')"
	#~ echo "LEFT=<$_left>"
	#~ echo "RIGHT=<$_right>"
	[ -n "${2:-}" ] && eval ${2}=\"\$_left\"
	[ -n "${3:-}" ] && eval ${3}=\"\$_right\"
	return 0
	;;
      \\|\"|\')
	j="$ch"
	;;
      esac
    elif [ x"$(expr substr "$j" 1 1)" = x"\\" ] ; then
      # Backslash... we skip it...
      j=$(expr substr "$j" 2 1) || :
    elif [ x"$j" = x"'" -o x"$j" = x"\"" ] ; then
      if [ x"$ch" = x"$j" ] ; then
	# Close it...
	j=""
      elif [ x"$ch" = x"\\" ] ;then
	j="\\$j"
      fi
    fi
    i=$(expr $i + 1)
  done
  # Nothing found...
  return 1
}

_pop_tag() {
  ## Remove "tag" from stack
  ## # USAGE
  ##	_pop_tag
  ## # DESC
  ## Remove tags from a stack.
  ##
  ## _pop_tag expects and modifies variables "tag", "pops" and "off"

  tag=$(set - $pops ; echo $1)
  pops=$(set - $pops ; shift ; echo $*)
  off="$(expr substr "$off" 1 $(expr $(expr length "$off") - 2))" || :
}

xmlgen() {
  ## Generate XML
  ## # Usage
  ##	xmlgen < in >out
  ## # DESC
  ## Read a "yaml"-like file and genrate "xml" for it.
  local \
	off="" \
	pops="" \
	ln="" left="" right="" tag=""
  _strip_hash_comments | (
    while read ln
    do
      [ -z "$ln" ] && continue
      if [ x"$ln" = x":" -o x"$ln" = x"/" ] ; then
	_pop_tag
	echo "$off</$tag>"
      elif _split_cfg_line "$ln" left right ; then
	# Found
	tag=$(echo "$left" | (read a b ; echo $a))
	if [ -z "$right" ] ; then
	  # Open tag...
	  echo "$off<$left>"
	  pops=$(echo $tag $pops)
	  off="  $off"
	else
	  # Single line content
	  echo "$off<$left>$right</$tag>"
	fi
      else
	# Self contained tag
	echo "$off<$ln />"
      fi
    done
    while [ -n "$pops" ]
    do
      _pop_tag
      echo "$off</$tag>"
    done
  )
}
