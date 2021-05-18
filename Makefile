# $ make
# $ make all
all: info

GIT = git
AIRFLOW = airflow
.PHONY: info $(GIT) $(AIRFLOW)

# $ make
info:
	@echo "GIT: $(GIT)"
	@echo "AIRFLOW: $(AIRFLOW)"

# $ make git
git:
	@bash ./scripts/git.sh
	
# $ make airflow
airflow:
	@bash ./scripts/airflow/airflow.sh
