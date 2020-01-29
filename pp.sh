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
ppEx() {
  ## Pre-processor
  ## USAGE
  ##	ppEx < input > output
  ## DESC
  ## Read 
  local eof="$$"
  eof="EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF"

  eval "$(sed -e 's/^/:/' | (
    mode='shell'
    while read -r line
    do
      if (echo "$line" | grep -q '^:[ \t]*##!') ; then
	case "$mode" in
	shell)
	  echo "$line" | sed -e 's/\(^:[ \t]*\)##!/\1/'
	  ;;
	heredoc)
	  echo ":$eof"
	  mode="shell"
	  ;;
	esac
      else
	case "$mode" in
	shell)
	  echo ":cat <<$eof"
	  echo "$line"
	  mode="heredoc"
	  ;;
	heredoc)
	  echo "$line"
	  ;;
	esac
      fi
    done
    [ "$mode" = "heredoc" ] && echo ":$eof"
    ) | sed -e 's/^://'
  )"
}

pp() {
  ## Pre-processor
  ## USAGE
  ##	ppEx < input > output
  ## DESC
  ## Read 
  local eof="$$"
  eof="EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF"
  local txt="$(echo "cat <<$eof" ; cat ; echo '' ;echo "$eof")"
  eval "$txt"
}
