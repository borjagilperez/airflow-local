# $ make
# $ make all
all: info

GIT = git
ESSENTIAL = essential
AIRFLOW = airflow
.PHONY: info $(GIT) $(ESSENTIAL) $(AIRFLOW)

# $ make
info:
	@echo "GIT: $(GIT)"
	@echo "ESSENTIAL: $(ESSENTIAL)"
	@echo "AIRFLOW: $(AIRFLOW)"

# $ make git
git:
	@bash ./scripts/git/git.sh

# $ make essential
essential:
	@bash ./scripts/essential/essential.sh
	
# $ make airflow
airflow:
	@bash ./scripts/airflow/airflow.sh
