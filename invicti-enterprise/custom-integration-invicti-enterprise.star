load('runzero.types', 'ImportAsset', 'Vulnerability')
load('requests', 'Session')
load('json', json_encode='encode', json_decode='decode')
load('uuid', 'new_uuid')
load('base64', 'b64encode')

API_URL = 'https://www.netsparkercloud.com/api/1.0/issues/list'


def severity_rank(sev):
    mapping = {
        'critical': 4,
        'high': 3,
        'medium': 2,
        'low': 1,
    }
    key = str(sev or '').lower()
    return mapping.get(key, 0)


def build_vulnerability(issue):
    rank = severity_rank(issue.get('Severity', ''))
    classification = issue.get('Classification', {})
    classification_json = encode(classification)
    vuln_id = issue.get('Id') or new_uuid()
    return Vulnerability(
        id=str(vuln_id),
        name=str(issue.get('Title', '')),
        description=str(issue.get('Remedy', '')),
        solution=str(issue.get('Remedy', '')),
        riskScore=float(rank),
        riskRank=rank,
        severityScore=float(rank),
        severityRank=rank,
        customAttributes={
            'url': issue.get('Url', ''),
            'classification': classification_json,
            'cvssVector': issue.get('CvssVectorString', ''),
        }
    )


def build_asset(website, issues):
    first = ''
    last = ''
    vulns = []
    for issue in issues:
        fs = issue.get('FirstSeenDate', '')
        ls = issue.get('LastSeenDate', '')
        if fs and (not first or fs < first):
            first = fs
        if ls and (not last or ls > last):
            last = ls
        vulns.append(build_vulnerability(issue))
    asset_id = issues[0].get('WebsiteId') or new_uuid()
    return ImportAsset(
        id=asset_id,
        hostnames=[website],
        firstSeen=first,
        lastSeen=last,
        vulnerabilities=vulns,
    )


def main(*args, **kwargs):
    user_id = kwargs.get('access_key')
    api_token = kwargs.get('access_secret')
    if not user_id or not api_token:
        print('Missing credentials')
        return None
    auth_string = '{}:{}'.format(user_id, api_token)
    encoded = b64encode(bytes(auth_string))
    auth_header = 'Basic {}'.format(encoded.decode())

    session = Session()
    session.headers.set('Authorization', auth_header)
    session.headers.set('Accept', 'application/json')

    response = session.get(API_URL)
    if response.status_code != 200:
        print('Invicti API error:', response.status_code)
        return None

    data = json_decode(response.body)
    issues = data.get('List', [])

    grouped = {}
    for issue in issues:
        site = issue.get('WebsiteRootUrl', '')
        if not site:
            continue
        if site not in grouped:
            grouped[site] = []
        grouped[site].append(issue)

    assets = []
    for site, site_issues in grouped.items():
        assets.append(build_asset(site, site_issues))

    return assets
