#!/bin/env python

"""
Examines state of jobs for all users
"""


import argparse
import requests


def main(args):
    user_list = load_users(args.user_list)
    active_users = detect_active_users(user_list, args)
    print(f"List of active users: {active_users}")
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


def detect_active_users(user_list, args):
    """Establish which users have useful output in cylc GUI"""

    base_url = "http://" + args.server + ":" + args.port
    active_users = []
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
        active_users.append(username)

    return active_users


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
