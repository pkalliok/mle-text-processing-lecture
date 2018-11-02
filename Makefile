
DATAFILES = data/fortunes_data.csv data/fortunes_labels.csv

.PHONY: all
all: predict

myenv:
	python3 -m venv myenv

stamps/configure-myenv: requirements.txt myenv
	./myenv/bin/pip install -r "$<"
	touch $@

# syntaxnet / parsey mcparseface rules

stamps/run-parsey:
	docker run -d --name parsey-mcparseface -p 7777:80 \
		andersrye/parsey-mcparseface-server
	until curl http://localhost:7777; do echo Waiting...; sleep 1; done
	touch $@

.PHONY: stop-parsey
stop-parsey:
	docker rm -f parsey-mcparseface
	-rm stamps/run-parsey

.PHONY: example-parse-text
example-parse-text: stamps/run-parsey
	./tools/parse-text How much wood would a woodchuck chuck, \
		if a woodchuck would chuck wood?

# Fortunes classification

data/fortunes.csv: ./tools/prepare-fortunes
	"$<" > "$@"

data/fortunes_data.csv: data/fortunes.csv
	cut -f2- "$<" > "$@"

data/fortunes_labels.csv: data/fortunes.csv
	. tools/functions.sh && cut -f1 "$<" | indexise > "$@"

data/fortunes.index: ./tools/text_model.py stamps/configure-myenv $(DATAFILES)
	"$<" learn data/fortunes $(DATAFILES)

.PHONY: predict
predict: ./tools/text_model.py data/fortunes.index
	"$<" show-predictions data/fortunes $(DATAFILES)

# Wikipedia classification

data/dbpedia_csv.tar.gz:
	curl -o "$@" https://raw.githubusercontent.com/srhrshr/torchDatasets/master/dbpedia_csv.tar.gz

data/dbpedia_csv: data/dbpedia_csv.tar.gz
	(cd data && tar xzf dbpedia_csv.tar.gz)
	touch $@

data/dbpedia_csv/train.csv: data/dbpedia_csv
	touch $@

data/dbpedia_csv/test.csv: data/dbpedia_csv
	touch $@

data/articles.bigrams: data/dbpedia_csv/train.csv data/dbpedia_csv/test.csv
	(echo 'sEpR sEpR'; \
	. tools/functions.sh && cut -d, -f2- $^ | \
	tokenise | bigrams | make_wordlist 20000) > "$@"

data/articles_labels.csv: data/dbpedia_csv/train.csv
	cut -d, -f1 "$<" > "$@"

data/articles_data.csv: data/dbpedia_csv/train.csv data/articles.bigrams
	. tools/functions.sh && cut -d, -f2- "$<" | \
	sed G | mark_record_separators '' | sed 's/sEpR/& &/' | \
	tokenise | bigrams | indexise_with_wordlist data/articles.bigrams | \
	recover_records | padlength 30 > "$@"

data/articles.index: ./tools/text_model.py stamps/configure-myenv \
		data/articles_labels.csv data/articles_data.csv
	"$<" learn data/articles data/articles_data.csv data/articles_labels.csv

# Fasttext examples

data/all_fortunes.txt:
	for f in /usr/share/games/fortunes/*.u8; do \
		echo "__label__`basename $$f .u8`"; cat "$$f"; done > "$@"

data/fortunes_model.bin: data/all_fortunes.txt
	./tools/fasttext skipgram -epoch 60 \
		-input "/$<" -output /data/fortunes_model

data/dbpedia_words.txt: data/dbpedia_csv/train.csv
	. tools/functions.sh && sed 's/^\([[:digit:]]*\),/__label__\1/' "$<" | \
	sed G | mark_record_separators '' | tokenise_english | \
	recover_records sEpR > "$@"

data/words_model.bin: data/dbpedia_words.txt
	./tools/fasttext skipgram -input "/$<" -output /data/words_model

