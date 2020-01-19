#!/usr/bin/env python3
import sys
import shlex

def quote_attr(word):
  rword = ''
  right = False
  for i in word:
    if right:
      if i == '"':
        rword += '&quot;'
      else:
        rword += i
    else:
      rword += i
      if i == '=':
        right = True
        rword += '"'
  if right: rword += '"'
  return rword

def quote_xml(word):
  rword = ''
  for i in word:
    if i == '<':
      rword += '&lt;'
    elif i == '>':
      rword += '&gt;'
    else:
      rword += i
  return rword

def process_file(fin):
  c_offsets = []

  for line in fin:
    line = line.rstrip('\r\n')
    off_l = len(line)
    line = line.lstrip()
    off_l = off_l - len(line)

    words = shlex.split(line, comments=True, posix=True)
    if len(words) == 0: continue

    while (len(c_offsets) > 0) and (c_offsets[-1][0] >= off_l):
      ctag = c_offsets.pop()
      print('%s</%s>' % (' ' * len(c_offsets), ctag[1]))

    colon = -1
    for i,word in enumerate(words):
      if word[-1:] == ':':
        words[i] = word[:-1]
        colon = i
        break

    if colon == -1:
      print('%s<%s />' % (' ' * len(c_offsets), line))
    elif colon == len(words)-1:
      # OK, opening section...
      print('%s<%s>' % (' ' * len(c_offsets), line[:-1]))
      c_offsets.append( [ off_l, words[0] ] )
    else:
      left = '<' ; ql = ''
      right = '>' ; qr = ''
      for i,word in enumerate(words):
        if i > colon:
          right += qr + quote_xml(word)
          qr = ' '
        else:
          left += ql + quote_attr(word)
          ql = ' '
      print('%s%s%s</%s>' % ( ' ' * len(c_offsets), left, right,  words[0]))
      
  while len(c_offsets) > 0:
    ctag = c_offsets.pop()
    print('%s</%s>' % (' ' * len(c_offsets), ctag[1]))


if __name__ == "__main__":
  process_file(sys.stdin)
  
