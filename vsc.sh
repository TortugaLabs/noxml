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
#
set -euf -o pipefail

mydir=$(dirname "$(readlink -f "$0")")
export LIBDIR="$(dirname "$mydir")/lib"
export PATH=$PATH:$mydir:$LIBDIR

. pp.sh
noxml() {
  python3 $mydir/noxml.py "$@"
}

if [ $# -eq 0 ] ; then
  echo "Usage: $0 {input.nxm} ..."
  exit 1
fi

while [ $# -gt 0 ]
do
  case "$1" in
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
for input in "$@"
do
  if [ x"$input" = x"-" ] ; then
    set -
    (export PATH="$(pwd):$PATH" ; pp | noxml) || rc=1
  else
    if [ ! -f "$input" ] ; then
      echo "$input: not found" 1>&2
      continue
    fi
    output=$(echo $input | sed -e 's/\.nxm$/.xml/')
    name=$(basename "$output" .xml)
    [ x"$input" = x"$output" ] && output="$input.xml"

    [ $# -gt 1 ] && echo -n "$input " 1>&2
    if ! ( exec <"$input" >"$output" ; export PATH="$(dirname "$input"):$PATH" ; pp | noxml ) ; then
      rc=1
      done='[ERROR]'
    fi
  fi
done

[ $# -gt 1 ] && echo "$done" 1>&2
exit $rc

