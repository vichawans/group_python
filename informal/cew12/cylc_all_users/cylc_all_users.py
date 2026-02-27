#!/bin/env python

"""
Examines state of jobs for all users
"""


import argparse
import re
import requests


def main(args):
    base_url = "http://" + args.server + ":" + args.port
    user_list = load_users(args.user_list)
    active_user_suite_pages = get_active_user_suite_pages(user_list, base_url)
    print(f"List of active users: {active_user_suite_pages.keys()}")
    active_jobs_by_user = {}
    for username, suite_page in active_user_suite_pages.items():
        active_jobs = get_active_jobs_by_user(username, suite_page, base_url)
        num_active_jobs=len(active_jobs)
        if num_active_jobs > 0:
            active_jobs_by_user[username] = active_jobs
            print(f"{username} has {num_active_jobs} listed jobs")
    pass


def load_users(user_file_path):
    """Load list of users from file and clean up any whitespace"""

    with open(user_file_path) as fd:
        all_users_raw = fd.readlines()
        all_users_trimmed = [name.strip() for name in all_users_raw]
    # Remove any blanks
    i = 0
    while i < len(all_users_trimmed):
        if not all_users_trimmed[i]:
            del all_users_trimmed[i]
        else:
            i += 1
    return all_users_trimmed


def get_active_user_suite_pages(user_list, base_url):
    """Establish which users have useful output in cylc GUI
       and fetch their top-level suite page.
       NOTE: defaults to 100/page, don't know how to fetch
       the rest as yet."""

    active_use_suite_pages = {}
    for username in user_list:
        request_params = {'user' : username}

        url = base_url +  "/suites"
        try:
            page_response = requests.get(url, request_params)
        except requests.exceptions.ConnectionError:
            print(f'WARNING: failed to get server response for user {username}, giving up')
            page_response = ""
            break

        if page_response.status_code != 200:
            # Normal to get 404 response for 'Path /home/users/xxxxx/cylc-run does not exist'
            continue

        print(f"Found active user: {username}")
        active_use_suite_pages[username] = page_response.text

        if len(active_use_suite_pages) >= 500:
            break # debug speed-up

    return active_use_suite_pages


# To match e.g. 'suite=u-dj365">task jobs list'
suite_matcher = re.compile(r'suite=([a-zA-Z0-9_/%-]+)">task jobs list')
def get_active_jobs_by_user(username, suite_page, args):
    suite_ids = suite_matcher.findall(suite_page)
    return suite_ids


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
                    prog="cylc_all_users.py",
                    description="Examines jobs for multiple users e.g. on Monsoon3")
    
    parser.add_argument("-u", "--user-list",
                        help="List of users on machine, one per line, from redirecting 'ls' output")
    parser.add_argument("-s", "--server",
                        default="127.0.0.1",
                        help="Server on which web GUI is running")
    parser.add_argument("-p", "--port",
                        default="8888",
                        help="Port on which web GUI can be accessed")
    
    args = parser.parse_args()

    main(args)
