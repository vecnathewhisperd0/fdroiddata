#!/usr/bin/env python3
# pylint: disable=invalid-name

"""
Check for every metadata if upstream provides fastlane metadata at the latest specified commit
If yes then remove description and summary from app metadata
"""

import os
import sys
import re
import glob
import requests
import yaml


def run(f):  # pylint: disable=too-many-return-statements,too-many-branches
    """
    Run the check and write to file specified as arg
    """
    with open(f) as fp:
        data = yaml.safe_load(fp)

    if "Builds" not in data:
        return
    if "Summary" not in data:
        if "Description" not in data:
            return
    if "Description" not in data:
        if "Summary" not in data:
            return

    builds = data["Builds"]
    latest_build = builds[len(builds) - 1]
    if "commit" not in latest_build:
        return
    latest_commit = latest_build["commit"]
    if "Repo" not in data:
        return
    repo = data["Repo"]
    repo_domain_search = re.search(
        r"([a-z0-9A-Z]\.)*[a-z0-9-]+\.([a-z0-9]{2,24})+(\.co\.([a-z0-9]{2,24})|\.([a-z0-9]{2,24}))*",  # pylint: disable=line-too-long
        repo,
    )
    if not repo_domain_search:
        return
    repo_domain = repo_domain_search.group()

    check_url = None

    if repo_domain == "github.com":
        check_url = (
            repo.replace(".git", "")
            + "/raw/"
            + latest_commit
            + "/fastlane/metadata/android/en-US/full_description.txt"
        )

    if repo_domain == "gitlab.com":
        check_url = (
            repo.replace(".git", "")
            + "/-/raw/"
            + latest_commit
            + "/fastlane/metadata/android/en-US/full_description.txt"
        )

    if not check_url:
        return

    request = requests.get(check_url)

    if (request.status_code == 200) or (request.status_code == 302):
        print(f)
        with open(f, "w") as output:
            if "Description" in data:
                del data["Description"]
            if "Summary" in data:
                del data["Summary"]
            output.write(yaml.dump(data))
        os.system("fdroid rewritemeta " + f[9:][:-4])


if len(sys.argv) == 1:
    for file in glob.glob("metadata/*.yml"):
        run(file)
else:
    run(sys.argv[1])
