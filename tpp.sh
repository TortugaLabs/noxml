#!/bin/sh
#
# Copyright (c) 2020 Alejandro Liu
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
#
set -euf -o pipefail

mydir=$(dirname "$(readlink -f "$0")")
export LIBDIR="$(dirname "$mydir")/lib"
export PATH=$PATH:$mydir:$LIBDIR

. pp.sh

if [ $# -eq 0 ] ; then
  echo "Usage: $0 {input.m.ext} ..."
  exit 1
fi

output=''
while [ $# -gt 0 ]
do
  case "$1" in
  -o*)
    if [ -z "${1#-o}" ] ; then
      output="$2" ; shift
    else
      output="${1#-o}"
    fi
    ;;
  --output=*)
    output="${1#--output=}"
    ;;
  -I*)
    export PATH="$PATH:${1#-I}"
    ;;
  -D*)
    eval "${1#-D}"
    ;;
  *)
    break
    ;;
  esac
  shift
done

rc=0
done='[OK]'
if [ -n "$output" ]  ; then
  name=$(echo "$output" | tr A-Z a-z | sed -e 's/^\([a-z0-9]*\).*$/\1/')
  [ x"$output" != x"-" ] && exec > "$output"
  for input in "$@"
  do
    if [ x"$input" = x"-" ] ; then
      set -
      if ! (export PATH="$(pwd):$PATH" ; ppEx ) ; then
        rc=1
        done='[ERROR]'
      fi
    else
      [ $# -gt 1 ] && echo -n "$input " 1>&2
      if ! ( exec <"$input" ; export PATH="$(dirname "$input"):$PATH" ; ppEx ) ; then
        rc=1
        done='[ERROR]'
      fi
    fi
  done
else
  for input in "$@"
  do
    if [ ! -f "$input" ] ; then
      echo '' 1>&2
      echo "$input: not found" 1>&2
      rc=1
      done='[ERROR]'
      continue
    fi

    name=$(echo "$input" | tr A-Z a-z | sed -e 's/^\([a-z0-9]*\).*$/\1/')
    output=$(echo "$input" | sed -e 's/\.m\.\([^.]*\)$/.\1/')
    [ x"$output" = x"$input" ] && output="$input.out"
  
    [ $# -gt 1 ] && echo -n "$input " 1>&2
    if ! ( exec <"$input" >"$output" ; export PATH="$(dirname "$input"):$PATH" ; ppEx ) ; then
      rc=1
      done='[ERROR]'
    fi
  done
fi

[ $# -gt 1 ] && echo "$done" 1>&2
exit $rc

