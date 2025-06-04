load('runzero.types', 'ImportAsset', 'NetworkInterface')
load('json', json_encode='encode', json_decode='decode')
load('requests', 'Session')
load('net', 'ip_address')
load('uuid', 'new_uuid')

SOLARWINDS_API_BASE = 'http://hostnameOrIPAddress:8787'
SWIS_QUERY_ENDPOINT = '/SolarWinds/InformationService/v3/Json/Query'
SWIS_QUERY = "SELECT NodeID, Caption, Vendor, MachineType, IPAddress, IOSVersion FROM Orion.Nodes"


def build_network_interface(ip):
    ip4s = []
    ip6s = []
    if ip:
        addr = ip_address(ip)
        if addr.version == 4:
            ip4s.append(addr)
        elif addr.version == 6:
            ip6s.append(addr)
    return NetworkInterface(ipv4Addresses=ip4s, ipv6Addresses=ip6s)


def build_assets(results):
    assets = []
    for item in results:
        node_id = item.get('NodeID') or new_uuid()
        hostname = item.get('Caption', '')
        manufacturer = item.get('Vendor', '')
        model = item.get('MachineType', '')
        ip = item.get('IPAddress', '')
        os_version = item.get('IOSVersion', '')
        network = build_network_interface(ip)
        assets.append(
            ImportAsset(
                id=str(node_id),
                hostnames=[hostname] if hostname else [],
                networkInterfaces=[network] if network else [],
                osVersion=os_version,
                manufacturer=manufacturer,
                model=model,
            )
        )
    return assets


def query_solarwinds(session):
    url = SOLARWINDS_API_BASE + SWIS_QUERY_ENDPOINT
    payload = { 'query': SWIS_QUERY }
    resp = session.post(url, body=bytes(encode(payload)))
    if not resp or resp.status_code != 200:
        print('Failed to query SolarWinds API')
        return []
    data = json_decode(resp.body)
    results = data.get('results') or data.get('Results') or []
    return results


def main(*args, **kwargs):
    username = kwargs.get('access_key')
    password = kwargs.get('access_secret')

    session = Session()
    session.headers.set('Content-Type', 'application/json')
    session.headers.set('Accept', 'application/json')
    session.auth = (username, password)

    results = query_solarwinds(session)
    if not results:
        print('No assets returned')
        return []

    assets = build_assets(results)
    return assets
