#!/usr/bin/env python
import argparse
import getpass
from stats import collect_and_push_job_stats


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--build-url', required=True)
    parser.add_argument('--mysql-host', required=True)
    parser.add_argument('--mysql-port', required=False, type=int, default=3306)
    parser.add_argument('--mysql-username', required=True)
    parser.add_argument('--mysql-password', required=False)
    parser.add_argument('--mysql-database', required=True)
    args = parser.parse_args()

    if not args.mysql_password:
        prompt = 'Enter password (for MySQL user {}): '.format(args.mysql_username)
        args.password = getpass.getpass(prompt=prompt)

    return args


def main():
    args = parse_args()
    collect_and_push_job_stats(args)


if __name__ == '__main__':
    main()
