
myenv:
	python3 -m venv myenv

stamps/configure-myenv: requirements.txt myenv
	./myenv/bin/pip install -r "$<"
	touch $@

