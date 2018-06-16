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
# --
# Common code for macro processing libraries
#
set -euf -o pipefail

m_error() {
  ## Handle error messages
  ## USAGE
  ##	m_error "message"
  ## DESC
  ## Will display a message on `stderr` prefixed with "ERROR:",
  ## and output the same message to stdout prefixed with "#".
  ##
  ## The rationale is that stdout is being saved to the output
  ## file, so we are marking the output with the error (as
  ## a comment).  While the console, will show the "ERROR" message
  ###
  echo "# $*"
  echo "ERROR: $*" 1>&2
  return 0
}

m_parse() {
  ## Parse command line arguments
  ## USAGE
  ##	local optname1="" optname2=""
  ##	local opts="optname1 optname2?"
  ##	m_parse cmd_name "$@" || return
  ## DESC
  ## Parse command-line switches for "key=value" pairs.
  ## "key" must have been defined in "$opts".  If "key" is not defined
  ## it is an error.
  ##
  ## If a key defined in "$opts" ends with "?", the key is treated
  ## as optional
  ##
  ## After all arguments are checked, it will make sure that all
  ## the $opts (which did not end with "?") have a value.
  local name="$1" ; shift
  local switch='case "$1" in'
  local i check=""
  for i in $opts
  do
    if (echo $i | grep -q '?$') ; then
      i=$(echo $i | sed -e 's/?$//')
    else
      if [ -z "$check" ] ; then
	check="$i"
      else
	check="$check $i"
      fi
    fi
    switch="$switch
	${i}=*) ${i}=\${1#$i=} ;; "
  done
  switch="$switch
	*) m_error \"$name: Invalid specification \\\"\$1\\\"\" ; return 1 ;;"
  switch="$switch
	esac"

  #echo "$switch"
  while [ $# -gt 0 ]
  do
    eval "$switch"
    shift
  done

  # Check if parameter is there...
  rc=0
  for i in $check
  do
    eval "local j=\${$i:-}"
    [ -n "$j" ] && continue
    rc=1
    m_error "$name: $i not specified"
  done

  return $rc
}

m_uuid() {
  ## Generate a random UUID
  ## USAGE
  ##	m_uuid
  if [ -f /proc/sys/kernel/random/uuid ] ; then
    cat /proc/sys/kernel/random/uuid
  else
    uuidgen
  fi
}
