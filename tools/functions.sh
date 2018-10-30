
freqs() {
 sort |
 uniq -c |
 sort -nr
}

ngrams() {
 sed "H;1,`expr $1 - 1` d;g;s/^[^\\n]*\\n//;h;s/\\n/ /g"
}

eqclasses() {
 awk '/^$/ { delete others; idx = 0; next; }
      { for (i = 0; i < idx; ++i) { print $0, others[i]; } 
        others[idx++] = $0; }'
}

bigrams() {
 awk 'prev && $0 { print prev, $0; } { prev = $0; }'
}

tokenise() {
 grep -o '[[:alnum:]]\{1,\}'
}

indexise() {
 awk '!trans[$0] {trans[$0]=++idx} {print trans[$0]}'
}

padlength() {
 cut "-f1-$1" |
 awk '{ pad=""; for (i = NF; i < '"$1"'; ++i) pad = pad "\t0"; print $0 pad; }'
}

word_vectors() {
 ( echo "$1"; cat - ) |
 sed "s/^$1$/sEpR/" |
 tokenise |
 indexise |
 tr \\012 \\011 |
 sed 's/^\(1\t\)*//;s/\t1\t/\n/g' |
 sed 's/\t*$//' |
 padlength "$2"
}

