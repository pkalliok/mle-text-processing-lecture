
DATAFILES = data/fortunes_data.csv data/fortunes_labels.csv

.PHONY: predict
predict: ./tools/text_model.py data/fortunes.index
	"$<" predict data/fortunes $(DATAFILES)

myenv:
	python3 -m venv myenv

stamps/configure-myenv: requirements.txt myenv
	./myenv/bin/pip install -r "$<"
	touch $@

data/fortunes.csv: ./tools/prepare-fortunes
	"$<" > "$@"

data/fortunes_data.csv: data/fortunes.csv
	cut -f2- "$<" > "$@"

data/fortunes_labels.csv: data/fortunes.csv
	. tools/functions.sh && cut -f1 "$<" | indexise > "$@"

data/fortunes.index: ./tools/text_model.py stamps/configure-myenv $(DATAFILES)
	"$<" learn data/fortunes $(DATAFILES)

