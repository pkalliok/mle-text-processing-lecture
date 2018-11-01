
DATAFILES = data/fortunes_data.csv data/fortunes_labels.csv

.PHONY: predict
predict: ./tools/text_model.py data/fortunes.index
	"$<" predict data/fortunes $(DATAFILES)

myenv:
	python3 -m venv myenv

stamps/configure-myenv: requirements.txt myenv
	./myenv/bin/pip install -r "$<"
	touch $@

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

data/fortunes.csv: ./tools/prepare-fortunes
	"$<" > "$@"

data/fortunes_data.csv: data/fortunes.csv
	cut -f2- "$<" > "$@"

data/fortunes_labels.csv: data/fortunes.csv
	. tools/functions.sh && cut -f1 "$<" | indexise > "$@"

data/fortunes.index: ./tools/text_model.py stamps/configure-myenv $(DATAFILES)
	"$<" learn data/fortunes $(DATAFILES)

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

