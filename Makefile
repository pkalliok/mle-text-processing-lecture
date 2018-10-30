
DATAFILES = data/fortunes_data.csv data/fortunes_labels.csv
analyse: ./tools/text_model.py stamps/configure-myenv $(DATAFILES)
	"$<" $(DATAFILES)

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

