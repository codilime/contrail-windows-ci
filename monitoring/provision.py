#!/usr/bin/env python
import argparse
import getpass
from sqlalchemy import create_engine
from database import MonitoringBase


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', required=True)
    parser.add_argument('--username', required=True)
    parser.add_argument('--password', required=False)
    parser.add_argument('--database', required=True)
    args = parser.parse_args()
    if not args.password:
        args.password = getpass.getpass(prompt='Enter password: ')
    return args


def get_mysql_connection_string(host, username, password, database):
    return 'mysql://{}:{}@{}/{}'.format(username, password, host, database)


def provision_database(connection_string, model):
    engine = create_engine(connection_string, echo=True)
    model.metadata.create_all(engine)


def main():
    args = parse_args()
    connection_string = get_mysql_connection_string(host=args.host, username=args.username,
                                                    password=args.password, database=args.database)
    provision_database(connection_string, model=MonitoringBase)


if __name__ == '__main__':
    main()

