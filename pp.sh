pp() {
  ## Pre-processor
  ## USAGE
  ##	pp < input > output
  ## DESC
  ## Read 
  local eof="$$" intxt="" shtxt=""
  eof="EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF"
  intxt="$(cat)"
  shtxt="$(
	echo "$intxt" | grep -E '^##!' | sed 's/^##!//'
	echo "cat <<$eof"
	echo "$intxt" | _strip_hash_comments
	echo ''
	echo "$eof"
      )"
  eval "$shtxt"
}

pp() {
  local eof="$$"
  eof="EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF"
  local txt="$(echo "cat <<$eof" ; cat ; echo '' ;echo "$eof")"
  eval "$txt"
}
