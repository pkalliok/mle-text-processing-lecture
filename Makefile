
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

data/fortunes.csv: ./tools/prepare-fortunes
	"$<" > "$@"

data/fortunes_data.csv: data/fortunes.csv
	cut -f2- "$<" > "$@"

data/fortunes_labels.csv: data/fortunes.csv
	. tools/functions.sh && cut -f1 "$<" | indexise > "$@"

data/fortunes.index: ./tools/text_model.py stamps/configure-myenv $(DATAFILES)
	"$<" learn data/fortunes $(DATAFILES)

.PHONY: example-parse-text
example-parse-text: stamps/run-parsey
	./tools/parse-text How much wood would a woodchuck chuck, \
		if a woodchuck would chuck wood?

