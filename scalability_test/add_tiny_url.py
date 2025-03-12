"""
Usage: add_tiny_url.py [OPTIONS]

  Create and register users into an allocation.

Options:
  --token			  TinyURL API token
  --url			          Target url
  --domain			  Domain for shortened url
  --alias			  Alias for shortened url
  --tags			  Tags (default: None)
  --expires			  Expires at (default: None)
  --description		          Link description (default: None)
  --help                          Show this message and exit.

"""

import requests
import click
import json

api_url = 'https://api.tinyurl.com'

@click.command()
@click.option("--token",help="Your TinyURL API token")
@click.option("--url",help="What target url to shorten")
@click.option("--domain",help="What domain to create shortened url in (e.g. tinyurl.com)")
@click.option("--alias",help="What name to make the shortened url in")
@click.option("--tags",default=None,help="What tags to associate with the shortened url (comma delimited if more than 1)")
@click.option("--expires",default=None,help="When the shortened url should expire")
@click.option("--description",default=None,help="Text description of the shortened url")

def add_tiny_url(token,url,domain,alias,tags,expires,description):
	headers = {"Authorization": f"Bearer {token}"}
	req_json = {
                "url":url,
                "domain":domain,
                "alias":alias,
                "tags":tags,
                "expires_at":expires,
                "description":description
        }
        response = requests.post(api_url+'/create', headers=headers, json=req_json)
	resp = json.loads(response.text)
	return resp['errors']==[]

if __name__ == "__main__":
    add_tiny_url()
