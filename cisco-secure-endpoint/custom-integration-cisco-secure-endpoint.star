load('runzero.types', 'ImportAsset', 'NetworkInterface', 'Vulnerability')
load('json', json_encode='encode', json_decode='decode')
load('net', 'ip_address')
load('http', http_post='post', http_get='get', 'url_encode')
load('uuid', 'new_uuid')
load('base64', base64_encode='encode')

# API endpoints
VISIBILITY_TOKEN_URL = 'https://visibility.amp.cisco.com/iroh/oauth2/token'
SECURE_ENDPOINT_TOKEN_URL = 'https://api.amp.cisco.com/v3/access_tokens'
API_BASE_URL = 'https://api.amp.cisco.com'
PAGE_SIZE = 500

def get_access_token(client_id, client_secret):
    auth_header = 'Basic ' + base64_encode(client_id + ':' + client_secret)
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'Authorization': auth_header,
    }
    body = bytes(url_encode({'grant_type': 'client_credentials'}))
    resp = http_post(VISIBILITY_TOKEN_URL, headers=headers, body=body)
    if resp.status_code != 200:
        print('failed to get visibility token', resp.status_code)
        return None
    token1 = json_decode(resp.body).get('access_token', '')
    if not token1:
        print('no token returned')
        return None

    headers2 = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'Authorization': 'Bearer ' + token1,
    }
    resp2 = http_post(SECURE_ENDPOINT_TOKEN_URL, headers=headers2, body=body)
    if resp2.status_code != 200:
        print('failed to get secure endpoint token', resp2.status_code)
        return None
    token2 = json_decode(resp2.body).get('access_token', '')
    if not token2:
        print('no access token returned')
        return None
    return token2

def get_computers(token):
    headers = {'Authorization': 'Bearer ' + token}
    offset = 0
    computers = []
    while True:
        params = {'limit': PAGE_SIZE, 'offset': offset}
        resp = http_get(API_BASE_URL + '/v1/computers', headers=headers, params=params)
        if resp.status_code != 200:
            print('failed to get computers', resp.status_code)
            return computers
        data = json_decode(resp.body)
        comps = data.get('data', [])
        computers.extend(comps)
        count = data.get('metadata', {}).get('results', {}).get('current_item_count', 0)
        if count < PAGE_SIZE:
            break
        offset += count
    return computers

def get_vulnerabilities(token, guid):
    headers = {'Authorization': 'Bearer ' + token}
    offset = 0
    vulns = []
    while True:
        params = {'limit': PAGE_SIZE, 'offset': offset}
        url = API_BASE_URL + '/v1/computers/' + guid + '/vulnerabilities'
        resp = http_get(url, headers=headers, params=params)
        if resp.status_code != 200:
            print('failed to get vulnerabilities for', guid, resp.status_code)
            return vulns
        body = json_decode(resp.body)
        items = body.get('data', {}).get('vulnerabilities', [])
        vulns.extend(items)
        count = body.get('metadata', {}).get('results', {}).get('current_item_count', 0)
        if count < PAGE_SIZE:
            break
        offset += count
    return vulns

def severity_rank(score):
    if score >= 9:
        return 4
    if score >= 7:
        return 3
    if score >= 4:
        return 2
    if score > 0:
        return 1
    return 0

def build_vulnerabilities(vuln_data):
    vulns = []
    for v in vuln_data:
        app = v.get('application', '')
        version = v.get('version', '')
        file = v.get('file', {})
        filename = file.get('filename', '')
        sha256 = file.get('identity', {}).get('sha256', '')
        for cve in v.get('cves', []):
            cve_id = cve.get('id', new_uuid())
            cvss = float(cve.get('cvss', 0))
            rank = severity_rank(cvss)
            vulns.append(
                Vulnerability(
                    id=str(cve_id),
                    name=str(cve_id),
                    description='%s %s' % (app, version),
                    cve=str(cve_id),
                    severityScore=cvss,
                    severityRank=rank,
                    riskScore=cvss,
                    riskRank=rank,
                    customAttributes={
                        'application': app,
                        'version': version,
                        'filename': filename,
                        'sha256': sha256,
                        'link': cve.get('link', ''),
                    },
                )
            )
    return vulns

def build_network_interface(ips, mac):
    ip4s = []
    ip6s = []
    for ip in ips[:99]:
        if not ip:
            continue
        ip_obj = ip_address(ip)
        if ip_obj.version == 4:
            ip4s.append(ip_obj)
        elif ip_obj.version == 6:
            ip6s.append(ip_obj)
    if not mac:
        return NetworkInterface(ipv4Addresses=ip4s, ipv6Addresses=ip6s)
    return NetworkInterface(macAddress=mac, ipv4Addresses=ip4s, ipv6Addresses=ip6s)

def build_networks(comp):
    nets = []
    addrs = comp.get('network_addresses', [])
    if addrs:
        for na in addrs:
            ip = na.get('ip', '')
            mac = na.get('mac', '')
            nets.append(build_network_interface([ip], mac))
    else:
        ips = []
        ips.extend(comp.get('internal_ips', []))
        ext = comp.get('external_ip', '')
        if ext:
            ips.append(ext)
        nets.append(build_network_interface(ips, None))
    return nets

def build_asset(comp, vulnerabilities):
    guid = comp.get('connector_guid', new_uuid())
    custom = {}
    for k in comp.keys():
        if k in ['connector_guid', 'hostname', 'network_addresses', 'internal_ips', 'external_ip']:
            continue
        val = comp.get(k)
        if type(val) == 'dict' or type(val) == 'list':
            custom[k] = encode(val)
        else:
            custom[k] = val
    return ImportAsset(
        id=str(guid),
        hostnames=[comp.get('hostname', '')],
        os=comp.get('operating_system', ''),
        osVersion=comp.get('os_version', ''),
        networkInterfaces=build_networks(comp),
        customAttributes=custom,
        vulnerabilities=vulnerabilities,
    )

def main(**kwargs):
    client_id = kwargs['access_key']
    client_secret = kwargs['access_secret']
    token = get_access_token(client_id, client_secret)
    if not token:
        print('authentication failed')
        return None
    computers = get_computers(token)
    if not computers:
        print('no computers found')
        return None
    assets = []
    for comp in computers:
        guid = comp.get('connector_guid', '')
        vulns_data = []
        if guid:
            vulns_data = get_vulnerabilities(token, guid)
        vulns = build_vulnerabilities(vulns_data)
        asset = build_asset(comp, vulns)
        assets.append(asset)
    return assets
