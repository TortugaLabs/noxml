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


# Select from: http://standards-oui.ieee.org/oui/oui.txt
# Random OUI
oui_random="44:d2:ca"
oui_prefix="b8:78:79"
oui_changed="d8:60:b0"

random_hex() {
  echo $(od -An -N1 -t x1 /dev/urandom)
}

m_macaddr() {
  echo ${1:-$oui_random}:$(random_hex):$(random_hex):$(random_hex)
}

m_disc_block() {
  local vdev="" path=""
  local opts="vdev path"
  m_parse m_disc_block "$@" || return 1
  cat <<-_EOF_
    # Storage configuration
    disk type="block" device="disk":
      source dev="$path"
      target dev="$vdev"
    :
	_EOF_
}
m_disc_file() {
  local vdev="" file=""
  local opts="vdev file"
  m_parse m_disc_file "$@" || return 1
  cat <<-_EOF_
    disk type="file" device="disk":
      source file="$file"
      target dev="$vdev"
    :
	_EOF_
}

m_cdrom_local() {
  local vdev="" iso=""
  local opts="vdev iso"
  m_parse m_cdrom_local "$@" || return 1
  cat <<-_EOF_
    disk type="file" device="cdrom":
      source file="$iso"
      target dev="$vdev"
    :
	_EOF_
}
m_cdrom_http() {
  local vdev="" url=""
  local opts="vdev url"
  m_parse m_cdrom_http "$@" || return 1

  local proto=$(echo "$url" | cut -d: -f1)
  local path=$(echo "$url" | cut -d: -f2- | sed -e 's!^//!!')
  local host=$(echo "$path" | cut -d/ -f1) port=80
  path=/$(echo "$path" | cut -d/ -f2-)
  if (echo $host | grep -q :) ; then
    port=$(echo $host | cut -d: -f2-)
    host=$(echo $host | cut -d: -f1)
  fi
  cat <<-_EOF_
    disk type="network" device="cdrom":
      source protocol="$proto" name="$path":
	host name="$host" port="$port"
      :
      target dev="$vdev"
    :
	_EOF_
}

m_net_brnic() {
  local br=br0 mac="" type="virtio"
  local opts="br mac? type"
  m_parse m_net_brnic "$@" || return 1
  [ -z "$mac" ] && mac=$(m_macaddr)
  [ $(expr length "$mac") -eq 8 ] && mac="$oui_prefix:$mac"

  cat <<-_EOF_
    interface type="bridge":
      source bridge="$br"
      mac address="$mac"
      model type="$type"
    :
	_EOF_
}


