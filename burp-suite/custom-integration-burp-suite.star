load('runzero.types', 'ImportAsset', 'NetworkInterface', 'Vulnerability')
load('json', json_encode='encode', json_decode='decode')
load('net', 'ip_address')
load('http', http_post='post')
load('uuid', 'new_uuid')

QUERY_SITES = """
query GetSiteTree {
  site_tree {
    sites {
      id
      name
      parent_id
    }
  }
}
"""

QUERY_SCANS = """
query GetScans($siteId: ID!) {
  site(id: $siteId) {
    scans {
      id
    }
  }
}
"""

QUERY_SCAN_ISSUES = """
query GetScanIssues($scanId: ID!) {
  scan(id: $scanId) {
    issues {
      serial_number
      severity
    }
  }
}
"""

QUERY_ISSUE = """
query getIssue($scanId: ID!, $serialNumber: ID!) {
  issue(scan_id: $scanId, serial_number: $serialNumber) {
    issue_type {
      name
      description_html
      remediation_html
    }
    severity
    description_html
    remediation_html
    serial_number
  }
}
"""

# Fetch the site list from Burp Suite Enterprise Edition
def graphql_post(base_url, token, query, variables=None):
    url = base_url.rstrip('/') + '/graphql/v1'
    headers = {
        'Authorization': token,
        'Content-Type': 'application/json'
    }
    body = encode({'query': query, 'variables': variables or {}})
    resp = http_post(url, headers=headers, body=bytes(body), timeout=300)
    if resp.status_code != 200:
        print('graphQL request failed', resp.status_code)
        return None
    data = json_decode(resp.body)
    return data.get('data')

def fetch_sites(base_url, token):
    data = graphql_post(base_url, token, QUERY_SITES)
    sites = []
    if data:
        sites = data.get('site_tree', {}).get('sites', [])
    return sites

def fetch_scans(base_url, token, site_id):
    data = graphql_post(base_url, token, QUERY_SCANS, {'siteId': site_id})
    scans = []
    if data and data.get('site'):
        scans = [s.get('id') for s in data['site'].get('scans', [])]
    return scans

def fetch_scan_issues(base_url, token, scan_id):
    data = graphql_post(base_url, token, QUERY_SCAN_ISSUES, {'scanId': scan_id})
    issues = []
    if data and data.get('scan'):
        issues = data['scan'].get('issues', [])
    return issues

def fetch_issue_details(base_url, token, scan_id, serial_number):
    vars = {'scanId': scan_id, 'serialNumber': serial_number}
    data = graphql_post(base_url, token, QUERY_ISSUE, vars)
    if data:
        return data.get('issue')
    return None

def build_vulnerabilities(base_url, token, scan_ids):
    vulns = []
    severity_map = {'CRITICAL': 4, 'HIGH': 3, 'MEDIUM': 2, 'LOW': 1}
    for sid in scan_ids:
        for issue in fetch_scan_issues(base_url, token, sid):
            serial = issue.get('serial_number')
            detail = fetch_issue_details(base_url, token, sid, serial)
            if not detail:
                continue
            issue_type = detail.get('issue_type', {})
            name = issue_type.get('name', '')
            severity = detail.get('severity', 'LOW').upper()
            rank = severity_map.get(severity, 0)
            vulns.append(
                Vulnerability(
                    id=str(serial),
                    name=name,
                    description=detail.get('description_html', ''),
                    solution=detail.get('remediation_html', ''),
                    severityRank=rank,
                    riskRank=rank,
                )
            )
    return vulns

# build runZero network interface placeholder
def build_network_interface():
    return NetworkInterface(ipv4Addresses=[ip_address('127.0.0.1')])

# convert sites to ImportAsset objects
def build_assets(base_url, token, sites):
    assets = []
    iface = build_network_interface()
    for s in sites:
        site_id = str(s.get('id', new_uuid))
        scan_ids = fetch_scans(base_url, token, site_id)
        vulns = build_vulnerabilities(base_url, token, scan_ids)
        assets.append(
            ImportAsset(
                id=site_id,
                hostnames=[s.get('name', '')],
                networkInterfaces=[iface],
                vulnerabilities=vulns,
                customAttributes={
                    'parentId': s.get('parent_id', ''),
                    'scanIds': ','.join(scan_ids),
                }
            )
        )
    return assets

# entry point for runZero
def main(**kwargs):
    base_url = kwargs.get('access_key', '').strip()
    token = kwargs['access_secret']
    sites = fetch_sites(base_url, token)
    if not sites:
        print('no sites retrieved')
        return None
    return build_assets(base_url, token, sites)
