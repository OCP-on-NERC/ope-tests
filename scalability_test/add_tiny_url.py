import requests
import click
import json
import sys


api_url = 'https://api.tinyurl.com'

@click.command()
@click.argument("api_token")
@click.argument("url")
@click.argument("domain")
@click.argument("alias")
@click.argument("tags", required=False)
@click.argument("expires", required=False)
@click.argument("description", required=False)

def add_tiny_url(api_token,url,domain,alias,
                 tags=None, expires=None, description=None):
    """
    Create a shortened URL using TinyURL API.

    Arguments:
      api_token       Your TinyURL API token
      url             What target url to shorten
      domain          What domain to create shortened url in (e.g. tinyurl.com)
      alias           What name to make the shortened url in
      tags            (Optional) What tags to associate with the shortened url
      expires         (Optional) When the shortened url should expire
      description     (Optional) Text description of the shortened url
    """
    headers = {"Authorization": f"Bearer {api_token}"}
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
    if resp.get("code") == 0:
        sys.exit(0) # success
    else:
        sys.exit(resp.get("code", 1)) # fail

if __name__ == "__main__":
    add_tiny_url()
