#!/usr/bin/env nix-shell
#! nix-shell -i python3.11 -p python311Packages.beautifulsoup4

from bs4 import BeautifulSoup

with open('template.html', 'r') as file:
    status_html = """
    <p><a href="~starptr">starptr</a> Jan 4</p>
    <p>Hello</p>
    """
    status_soup = BeautifulSoup(status_html, 'html.parser')

    page = file.read()
    soup = BeautifulSoup(page, 'html.parser')
    container = soup.select_one("#status-container")
    container.append(status_soup)
    print(soup.prettify())