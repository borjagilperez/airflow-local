#!/bin/bash

PS3="Please select your choice: "
options=(
    "Install" \
    "Run" \
    "Stop" \
    "Clean" \
    "Add variables" \
    "Uninstall" \
    "Quit")

select opt in "${options[@]}"; do
    case $opt in
        "Install")
            export AIRFLOW_HOME=$HOME/airflow

            cmd="CREATE USER airflow WITH ENCRYPTED PASSWORD 'airflow'; CREATE DATABASE airflow2; GRANT ALL PRIVILEGES ON DATABASE airflow2 TO airflow;"
            echo $cmd | sudo -u postgres psql

            eval "$($HOME/miniconda/bin/conda shell.bash hook)"
            conda env create -f ./scripts/airflow/environment.yml
            conda activate airflow_env && conda info --envs
            airflow db init

            export VAULT_ADDR='http://127.0.0.1:8200'
            vault login
            read -p 'Owner: ' owner
            branch=$(git branch | grep '*' | awk -F' ' 'NR==1{print $2}')
            
            python3 ./scripts/airflow/replace_airflow_cfg.py airflow-local \
                $(vault kv get -format=json kv/$owner/$branch/airflow/local/dags-folder | jq -r .data.data.value) \
                $(vault kv get -format=json kv/$owner/$branch/airflow/local/smtp | jq -r .data.data.host) \
                $(vault kv get -format=json kv/$owner/$branch/airflow/local/smtp | jq -r .data.data.mail_from) \
                $(vault kv get -format=json kv/$owner/$branch/airflow/local/smtp | jq -r .data.data.password) \
                $(vault kv get -format=json kv/$owner/$branch/airflow/local/smtp | jq -r .data.data.port) \
                $(vault kv get -format=json kv/$owner/$branch/airflow/local/smtp | jq -r .data.data.ssl) \
                $(vault kv get -format=json kv/$owner/$branch/airflow/local/smtp | jq -r .data.data.starttls) \
                $(vault kv get -format=json kv/$owner/$branch/airflow/local/smtp | jq -r .data.data.user)

            airflow db reset -y
            
            files="$(vault kv get -format=json kv/$owner/$branch/airflow/local/variables-folder | jq -r .data.data.value)/*"
            for file in $files; do
                echo "$file $(airflow variables import $file)"
            done
            
            airflow users create \
                --username admin \
                --password admin \
                --role Admin \
                --email admin@example.com \
                --firstname admin \
                --lastname admin

            break
            ;;
        
        "Run")
            export AIRFLOW_HOME=$HOME/airflow
            eval "$($HOME/miniconda/bin/conda shell.bash hook)"
            conda activate airflow_env && conda info --envs
            airflow webserver --daemon
            airflow scheduler --daemon
            echo -e "\nURL: $(cat $AIRFLOW_HOME/airflow.cfg | grep 'base_url = ' | awk -F' = ' '{print $2}')"

            break
            ;;

        "Stop")
            export AIRFLOW_HOME=$HOME/airflow
            kill -s TERM $(cat $AIRFLOW_HOME/airflow-scheduler.pid)
            kill -s TERM $(cat $AIRFLOW_HOME/airflow-webserver.pid)

            break
            ;;

        "Clean")
            export AIRFLOW_HOME=$HOME/airflow
            rm -f $AIRFLOW_HOME/*.pid

            break
            ;;

        "Add variables")
            export AIRFLOW_HOME=$HOME/airflow
            eval "$($HOME/miniconda/bin/conda shell.bash hook)"
            conda activate airflow_env && conda info --envs

            export VAULT_ADDR='http://127.0.0.1:8200'
            vault login
            read -p 'Owner: ' owner
            branch=$(git branch | grep '*' | awk -F' ' 'NR==1{print $2}')
            
            files="$(vault kv get -format=json kv/$owner/$branch/airflow/local/variables-folder | jq -r .data.data.value)/*"
            for file in $files; do
                echo "$file $(airflow variables import $file)"
            done
            
            break
            ;;

        "Uninstall")
            export AIRFLOW_HOME=$HOME/airflow

            eval "$($HOME/miniconda/bin/conda shell.bash hook)"
            conda activate base && conda info --envs
            conda remove -y -n airflow_env --all
            conda clean -y --all

            rm -rf $AIRFLOW_HOME
            cmd="drop database airflow2;"
            echo $cmd | sudo -u postgres psql

            break
            ;;

        "Quit")
            break
            ;;
        *)
            echo "Invalid option"
            break
            ;;
    esac
done
