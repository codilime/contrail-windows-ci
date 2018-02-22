#!/usr/bin/env python
import argparse
import getpass
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from stats import collect_and_push_job_stats


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--job-name', required=True)
    parser.add_argument('--build-url', required=True)
    parser.add_argument('--mysql-host', required=True)
    parser.add_argument('--mysql-username', required=True)
    parser.add_argument('--mysql-password', required=False)
    parser.add_argument('--mysql-database', required=True)
    args = parser.parse_args()

    if not args.mysql_password:
        prompt = 'Enter password (for MySQL user {}): '.format(args.mysql_username)
        args.password = getpass.getpass(prompt=prompt)

    return args


def get_mysql_connection_string(host, username, password, database):
    return 'mysql://{}:{}@{}/{}'.format(username, password, host, database)


def main():
    args = parse_args()

    conn_string = get_mysql_connection_string(host=args.mysql_host, username=args.mysql_username,
                                              password=args.mysql_password,
                                              database=args.mysql_database)
    engine = create_engine(conn_string)
    session_factory = sessionmaker()
    session_factory.configure(bind=engine)
    session = session_factory()

    collect_and_push_job_stats(job_name=args.job_name, build_url=args.build_url, db_session=session)


if __name__ == '__main__':
    main()
