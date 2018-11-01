
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

tokenise_english() {
 egrep -o "([do]')?[[:alnum:]_]+('[sd]|n't|'ve)?|([Ii]nc|[Ll]td|[Cc]o(rp)?|Mr|Dr|Ms|[[:upper:]])\\.|[;:,.?!'\"()]" |
 awk '/^\.$/ { sentence=1; print; next; }
      sentence { print tolower(substr($0,1,1)) substr($0,2); sentence=0; next; }
      { print }'
}

indexise() {
 awk '!trans[$0] {trans[$0]=++idx} {print trans[$0]}'
}

make_wordlist() {
 freqs | head "-$1" | cut -c9-
}

indexise_with_wordlist() {
 awk 'NR==FNR {trans[$0]=NR; next;} trans[$0] {print trans[$0]}' "$1" -
}

index_decode_with_wordlist() {
 awk 'NR==FNR {trans[NR]=$0; next;}
      trans[$0] {print trans[$0]; next; }
      { print; }' "$1" -
}

padlength() {
 cut "-f1-$1" |
 awk '{ pad="";
	if (!$0) $0 = "0";
	for (i = NF; i < '"$1"'; ++i) pad = pad "\t0";
	print $0 pad; }'
}

mark_record_separators() {
 ( echo "$1"; cat - ) |
 sed "s/^$1\$/sEpR/"
}

recover_records() {
 SEPARATOR="$1"
 test -z "$SEPARATOR" && SEPARATOR="1"
 awk '/^'"$SEPARATOR"'$/ && !started { next; }
      /^'"$SEPARATOR"'$/ { print record; record=""; next; }
      END { if (record) print record; }
      { started=1;
	if (!record) record = $0;
	else record = record "\t" $0; }'
}

word_vectors() {
 mark_record_separators "$1" |
 tokenise |
 indexise |
 recover_records |
 padlength "$2"
}

