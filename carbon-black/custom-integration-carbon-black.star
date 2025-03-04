load('runzero.types', 'ImportAsset', 'NetworkInterface')
load('json', json_encode='encode', json_decode='decode')
load('net', 'ip_address')
load('http', http_post='post', http_get='get', 'url_encode')

CARBON_BLACK_HOST = "<UPDATE_ME>"  # Example: https://defense.conferdeploy.net
ORG_KEY = "<UPDATE_ME>"  # Carbon Black Org Key
SCROLL_API_URL = "{}/appservices/v6/orgs/{}/devices/_scroll".format(CARBON_BLACK_HOST, ORG_KEY)
PAGE_SIZE = 1000  # Maximum number of devices per request

def get_devices(api_key):
    """Retrieve all devices from Carbon Black Cloud API using _scroll for large datasets"""
    headers = {
        "X-Auth-Token": api_key,
        "Content-Type": "application/json",
    }

    devices = []
    
    # Step 1: Start the scroll session
    payload = {
        "criteria": {},
        "rows": PAGE_SIZE
    }
    response = http_post(SCROLL_API_URL, headers=headers, body=bytes(json_encode(payload)))

    if response.status_code != 200:
        print("Failed to start scroll session. Status: {}".format(response.status_code))
        return devices

    response_json = json_decode(response.body)
    batch = response_json.get("results", [])
    scroll_id = response_json.get("scroll_id", None)

    if not batch or not scroll_id:
        print("No devices returned or missing scroll_id.")
        return devices

    devices.extend(batch)

    # Step 2: Continue fetching batches using scroll_id
    while scroll_id:
        payload = {"scroll_id": scroll_id}
        response = http_post(SCROLL_API_URL, headers=headers, body=bytes(json_encode(payload)))

        if response.status_code != 200:
            print("Failed to retrieve next batch. Status: {}".format(response.status_code))
            break

        response_json = json_decode(response.body)
        batch = response_json.get("results", [])
        scroll_id = response_json.get("scroll_id", None)

        if not batch:
            break  # No more data to retrieve

        devices.extend(batch)

    return devices

def build_assets(devices):
    """Convert Carbon Black devices into runZero assets"""
    assets = []
    
    for device in devices:
        device_id = str(device.get("id", ""))
        hostname = device.get("name", "")
        os = device.get("os", "")
        os_version = device.get("os_version", "")
        ip = device.get("last_internal_ip_address", "")
        external_ip = device.get("last_external_ip_address", "")
        mac = device.get("mac_address", "")

        # Build network interfaces
        network = build_network_interface(ips=[ip, external_ip], mac=mac if mac else None)

        # Dynamically build customAttributes with all available data
        custom_attrs = {key: json_encode(value) if isinstance(value, (dict, list)) else str(value) for key, value in device.items()}

        assets.append(
            ImportAsset(
                id=device_id,
                hostnames=[hostname],
                os=os,
                osVersion=os_version,
                networkInterfaces=[network],
                customAttributes=custom_attrs
            )
        )

    return assets

def build_network_interface(ips, mac):
    """Build runZero network interfaces"""
    ip4s = []
    ip6s = []

    for ip in ips[:99]:
        if ip:
            ip_addr = ip_address(ip)
            if ip_addr.version == 4:
                ip4s.append(ip_addr)
            elif ip_addr.version == 6:
                ip6s.append(ip_addr)

    return NetworkInterface(macAddress=mac, ipv4Addresses=ip4s, ipv6Addresses=ip6s)

def main(**kwargs):
    """Main function for Carbon Black integration"""
    api_key = kwargs['access_secret']  # API key provided via runZero credential

    devices = get_devices(api_key)
    
    if not devices:
        print("No devices found.")
        return None

    assets = build_assets(devices)
    
    if not assets:
        print("No assets created.")
    
    return assets
