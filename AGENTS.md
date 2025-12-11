# Custom Integration Agents

This document provides guidance for creating custom integration scripts for runZero.

## Goal
Create a custom integration script to import assets into runZero from a third-party service (Inbound) or export runZero assets to a third-party service (Outbound).

## Directory Structure
Each integration must be placed in its own directory at the root of the repository.

```
repo-root/
├── <integration-name>/
│   ├── custom-integration-<integration-name>.star  # The main script
│   ├── config.json                                 # Metadata
│   └── README.md                                   # Documentation
```

### 1. `config.json`
This file contains metadata about the integration.

**Format:**
```json
{
  "name": "Integration Name",
  "type": "inbound"
}
```
*   `type`: Use `"inbound"` for importing assets into runZero, `"outbound"` for exporting assets from runZero.

### 2. `custom-integration-<name>.star`
This is the main script written in Starlark.

## Script Development

### Language
The script is written in **Starlark**, a Python-like language with some key differences:
*   **No Exceptions**: Use return values and status codes for error handling.
*   **No f-strings**: Use `"{}".format(var)` for string interpolation.
*   **Limited Standard Library**: Only specific built-ins and loaded libraries are available.

### Entrypoint
The script must define a `main` function.

```python
def main(*args, **kwargs):
    # Your logic here
    return assets # List of ImportAsset objects (for inbound) or None
```

*   **Arguments**:
    *   `kwargs['access_key']`: Typically the username, client ID, or organization ID.
    *   `kwargs['access_secret']`: Typically the password, API token, or secret key.

### Return Type
*   **Inbound**: Must return a `list` of `ImportAsset` objects.
*   **Outbound**: Typically returns `None` after performing the export operation.

### Available Libraries
Load libraries at the top of your script.

```python
load('runzero.types', 'ImportAsset', 'NetworkInterface', 'Software', 'Vulnerability')
load('json', json_encode='encode', json_decode='decode')
load('net', 'ip_address')
load('http', http_post='post', http_get='get', 'url_encode')
load('uuid', 'new_uuid')
load('time', 'parse_time')
```

### Best Practices

1.  **Pagination**: APIs often return paginated results. Use `while` loops to fetch all data.
    ```python
    while url:
        response = http_get(url, headers=headers)
        if response.status_code != 200:
            break
        data = json_decode(response.body)
        # Process data...
        # Update url for next page or break
    ```

2.  **Error Handling**: Check `response.status_code` after every HTTP request.
    ```python
    if response.status_code != 200:
        print("Error: {}".format(response.status_code))
        return []
    ```

3.  **Data Mapping**: Map third-party fields to `ImportAsset` fields carefully.
    *   `id`: unique identifier (string).
    *   `hostnames`: list of strings.
    *   `os`, `osVersion`: strings.
    *   `networkInterfaces`: list of `NetworkInterface` objects.
    *   `customAttributes`: dict for any extra data.

4.  **Network Interfaces**: Use `ip_address` to validate and categorize IPs (IPv4 vs IPv6).
    ```python
    def build_network_interface(ips, mac):
        ip4s = []
        ip6s = []
        for ip in ips:
            addr = ip_address(ip)
            if addr.version == 4:
                ip4s.append(addr)
            elif addr.version == 6:
                ip6s.append(addr)
        return NetworkInterface(macAddress=mac, ipv4Addresses=ip4s, ipv6Addresses=ip6s)
    ```

## Testing

Use the `runzero` CLI to test your script locally.

1.  **Run with arguments**:
    ```bash
    runzero script --filename <path/to/script.star> --kwargs access_key=MY_KEY --kwargs access_secret=MY_SECRET
    ```

2.  **REPL**:
    ```bash
    runzero script repl --filename <path/to/script.star>
    ```

## Example Template (Inbound)

```python
load('runzero.types', 'ImportAsset', 'NetworkInterface')
load('json', json_decode='decode')
load('net', 'ip_address')
load('http', http_get='get')

API_URL = "https://api.example.com/devices"

def build_network_interface(ips, mac):
    ip4s = []
    ip6s = []
    for ip in ips:
        if not ip: continue
        addr = ip_address(ip)
        if addr.version == 4:
            ip4s.append(addr)
        elif addr.version == 6:
            ip6s.append(addr)
    return NetworkInterface(macAddress=mac, ipv4Addresses=ip4s, ipv6Addresses=ip6s)

def main(**kwargs):
    api_key = kwargs.get('access_secret')
    headers = {"Authorization": "Bearer {}".format(api_key)}

    assets = []
    response = http_get(API_URL, headers=headers)

    if response.status_code != 200:
        print("API Error: {}".format(response.status_code))
        return []

    devices = json_decode(response.body)

    for device in devices:
        assets.append(ImportAsset(
            id=device.get("id"),
            hostnames=[device.get("hostname")],
            os=device.get("os"),
            networkInterfaces=[build_network_interface(device.get("ips", []), device.get("mac"))],
            customAttributes={"serial": device.get("serial")}
        ))

    return assets
```
