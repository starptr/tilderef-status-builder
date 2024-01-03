#!/usr/bin/env nix-shell
#! nix-shell -i python3.11 -p python311Packages.beautifulsoup4

import os
import re
import glob
import sqlite3
from bs4 import BeautifulSoup

# Note for posterity: if this copy of the script is ran by users, do not directly edit / develop
# on this file. Development of this file should happen in the private git repo copy, and released
# versions of the script should fully copy the directory into the location available in $PATH.

all_statuses = []

status_dbs = glob.glob('/home/*/.status/*.db')
displayname_regcompiled = re.compile(r'([^\\\/\.]+).db$')
tildename_regcompiled = re.compile(r'^\/home\/([^\/\\]+)\/')
for path in status_dbs:
    displayname_regresult = displayname_regcompiled.search(path)
    tildename_regresult = tildename_regcompiled.search(path)
    displayname = displayname_regresult.group(1)
    tildename = tildename_regresult.group(1)

    connection = sqlite3.connect(path)
    cursor = connection.cursor()
    res = cursor.execute("SELECT idx, date, status, datestamp FROM statuses WHERE NOT hide")
    statuses = res.fetchall()

    statuses = map(lambda tup: {
        "tildename": tildename,
        "displayname": displayname,
        "idx": tup[0],
        "date": tup[1],
        "status": tup[2],
        "datestamp": tup[3]
    }, statuses)

    # Ensure idx and datestamp is int, date and status are strings
    valid_statuses = list(filter(lambda status: isinstance(status["datestamp"], int)
                                and isinstance(status["idx"], int)
                                and isinstance(status["date"], str)
                                and isinstance(status["status"], str), statuses))
    
    all_statuses += valid_statuses

# Sort by datestamp
all_statuses = list(sorted(all_statuses, key=lambda status: status["datestamp"], reverse=True))

with open('/home/starptr/src/status-builder/template.html', 'r') as file:
    statuses_html = "\n".join(map(lambda status: (
        f'<div>'
        f'  <p><a href="~{status["tildename"]}">{status["displayname"]}</a> {status["date"]}</p>'
        f'  <p>{status["status"]}</p>'
        f'</div>'
    ), all_statuses))
    status_soup = BeautifulSoup(statuses_html, 'html.parser')

    page = file.read()
    soup = BeautifulSoup(page, 'html.parser')
    container = soup.select_one("#status-container")
    container.append(status_soup)
    script_dir = os.path.dirname(__file__)
    build_file_path = os.path.join(script_dir, "build_html/status.html")
    def opener(path, flags):
        return os.open(path, flags, 0o777)
    with open(build_file_path, 'w', opener=opener) as fout:
        fout.write(str(soup))
    #os.chmod(build_file_path, 0o777)
    print("Status page built successfully")