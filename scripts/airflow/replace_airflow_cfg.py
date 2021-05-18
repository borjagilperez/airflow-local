# -*- coding: utf-8 -*-

import argparse
import errno
import os
import sys
from pathlib import Path

def __parse_args():

    parent_parser = argparse.ArgumentParser(add_help=False)
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='subparser')
    list_parser = subparsers.add_parser("airflow-local", parents=[parent_parser], help="airflow-local configuration")
    list_parser.add_argument("smtp_host", metavar="smtp-host", help="SMTP host")
    list_parser.add_argument("smtp_mail_from", metavar="smtp-mail-from", help="SMTP mail from")
    list_parser.add_argument("smtp_password", metavar="smtp-password", help="SMTP password")
    list_parser.add_argument("smtp_port", metavar="smtp-port", help="SMTP port")
    list_parser.add_argument("smtp_ssl", metavar="smtp-ssl", help="SMTP ssl")
    list_parser.add_argument("smtp_starttls", metavar="smtp-starttls", help="SMTP starttls")
    list_parser.add_argument("smtp_user", metavar="smtp-user", help="SMTP user")

    args = parser.parse_args()
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(errno.EAGAIN)
    else:
        args = parser.parse_args()

    return args

def __main(args):

    home = str(Path.home())
    with open(os.path.join(home, 'airflow/airflow.cfg'), 'rt') as f:
        cfg = f.read()

    # Local executor
    cfg = cfg.replace("executor = SequentialExecutor", "executor = LocalExecutor")
    # Load examples
    cfg = cfg.replace("load_examples = True", "load_examples = False")
    # Web server port
    cfg = cfg.replace("8080", "8181")
    # DAGs folder
    cfg = cfg.replace(
        f"dags_folder = {os.path.join(home, 'airflow/dags')}",
        f"dags_folder = {os.path.join(home, 'Git/airflow-dags/dags/local')}"
    )
    # Postgresql
    cfg = cfg.replace(
        f"sql_alchemy_conn = sqlite:///{home}/airflow/airflow.db",
        f"sql_alchemy_conn = postgresql+psycopg2://airflow:airflow@localhost:5432/airflow2"
    )
    # SMT
    cfg = cfg.replace("smtp_host = localhost", f"smtp_host = {args.smtp_host}")
    cfg = cfg.replace("smtp_mail_from = airflow@example.com", f"smtp_mail_from = {args.smtp_mail_from}")
    cfg = cfg.replace("# smtp_password =", f"smtp_password = {args.smtp_password}")
    cfg = cfg.replace("smtp_port = 25", f"smtp_port = {args.smtp_port}")
    cfg = cfg.replace("smtp_ssl = False", f"smtp_ssl = {args.smtp_ssl}")
    cfg = cfg.replace("smtp_starttls = True", f"smtp_starttls = {args.smtp_starttls}")
    cfg = cfg.replace("# smtp_user =", f"smtp_user = {args.smtp_user}")

    with open(os.path.join(home, f"airflow/airflow.cfg"), 'wt') as f:
        f.write(cfg)

if __name__ == "__main__":

    args = __parse_args()
    __main(args)
    