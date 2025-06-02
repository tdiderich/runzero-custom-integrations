load('runzero.types', 'ImportAsset', 'NetworkInterface')
load('json', json_encode='encode', json_decode='decode')
load('net', 'ip_address')
load('http', http_post='post', http_get='get', 'url_encode')
load('uuid', 'new_uuid')

STAIRWELL_API_URL = 'https://app.stairwell.com'

def get_assets(env, token):
    hasNextPage = True
    page_size = 5
    assets_all = []

    url = STAIRWELL_API_URL + "/v1/environments/" + env + "/assets"
    headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token}
    params = {'limit': page_size}

    while hasNextPage:
        response = http_get(url, headers=headers, params=params)
        if response.status_code != 200:
            print('failed to retrieve assets', response.status_code)
            return None

        assets = json_decode(response.body)

        for a in assets.get('assets', ''):
            assets_all.append(a)

        next_token = assets.get('nextPageToken', '')
        if next_token:
            params = {'next_page_token': next_token, 'limit': page_size}
        else:
            hasNextPage = False

    return assets_all

def build_assets(assets_json):
    imported_assets = []
    for item in assets_json:

        # parse ip address
        ips = []
        ip = item.get('ipAddress', '')

        # check for no ip address
        if not ip:
            ip = '127.0.0.1'

        # strip interface from ipv6 address
        if '%' in ip:
            ip = ip.split('%')[0]

        ips.append(ip)

        # parse mac address
        macs = []
        mac = item.get('macAddress', '')

        if not mac or mac == '-':
            continue
        else:
            macs.append(mac)

        # create network interfaces
        networks = []
        if macs:
            for m in macs:
                network = build_network_interface(ips=ips, mac=m)
                networks.append(network)
        else:
            network = build_network_interface(ips=ips, mac=None)
            networks.append(network)

        # parse operating system
        os_raw = item.get('os', '')
        os_version_raw = item.get('osVersion', '')

        if 'macOS' in os_raw:
            os = 'macOS ' + os_version_raw
        elif 'Ubuntu' in os_raw:
            os = 'Ubuntu ' + os_version_raw
        elif 'Linux' in os_raw:
            os = 'Linux'
        else:
            os = os_raw

        # still need to sort out tag parsing and add logic to convert lastCheckinTime to epoch format

        imported_assets.append(
            ImportAsset(
                id=str(item.get('name', '').split('/')[1]),
                hostnames=[item.get('label', '')],
                networkInterfaces=networks,
                os=os,
                osVersion = item.get('osVersion', ''),
                customAttributes={
                    'createTime':item.get('createTime', ''),
                    'lastCheckinTime':item.get('lastCheckinTime', ''),
                    'environment':item.get('environment', ''),
                    'forwarderVersion':item.get('forwarderVersion', ''),
                    'uploadToken':item.get('uploadToken', ''),
                    'backscanState':item.get('backscanState', ''),
                    'os.raw':os_raw,
                    'state':item.get('state', '')
                }
            )
        )
    return imported_assets

# build runZero network interfaces; shouldn't need to touch this
def build_network_interface(ips, mac):
    ip4s = []
    ip6s = []
    for ip in ips[:99]:
        ip_addr = ip_address(ip)
        if ip_addr.version == 4:
            ip4s.append(ip_addr)
        elif ip_addr.version == 6:
            ip6s.append(ip_addr)
        else:
            continue
    if not mac:
        return NetworkInterface(ipv4Addresses=ip4s, ipv6Addresses=ip6s)
    
    return NetworkInterface(macAddress=mac, ipv4Addresses=ip4s, ipv6Addresses=ip6s)

def main(**kwargs):
    # kwargs!!
    env = kwargs['access_key']
    token = kwargs['access_secret']
    
    # get assets
    assets = get_assets(env, token)
    if not assets:
        print('failed to retrieve assets')
        return None

    # build asset import
    imported_assets = build_assets(assets)
    
    return imported_assets