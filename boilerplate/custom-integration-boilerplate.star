# This script demonstrates how to import and use all of the runZero custom Starlark libraries.
# 
# The libraries are:
#
#   1. runzero.types (ImportAsset, NetworkInterface, Software, Vulnerability)
#   2. json (json_encode="encode", json_decode="decode")
#   3. net (ip_address)
#   4. http (http_post="post", http_get="get", url_encode)
#   5. uuid (new_uuid)
#
# The main() function also shows how to use the Credentials stored in runZero with the **kwargs input. 

load("runzero.types", "ImportAsset", "NetworkInterface", "Software", "Vulnerability")
load("json", json_encode="encode", json_decode="decode")
load("net", "ip_address")
load("http", http_post="post", http_get="get", "url_encode")
load("uuid", "new_uuid")


# -------------------------
# runzero.types (3 examples)
# -------------------------

def create_asset_example():
    """
    Demonstrates how to create an ImportAsset object, which is used
    to represent a device or endpoint for ingestion into runZero.

    Returns:
        ImportAsset: a populated ImportAsset object
    """
    # Minimal example: single network interface, hostnames, OS, etc.
    # Normally, you'll populate these from real data.
    netif = NetworkInterface(
        ipv4Addresses=["192.168.1.10"],
        macAddress="AA:BB:CC:DD:EE:FF"
    )
    return ImportAsset(
        id="asset-12345",
        networkInterfaces=[netif],
        hostnames=["sample-device"],
        os="ExampleOS",
        osVersion="1.0"
    )

def create_software_example():
    """
    Demonstrates how to create a Software object, which can be attached
    to an ImportAsset for software inventory tracking.

    Returns:
        Software: a populated Software object
    """
    return Software(
        id="software-456",
        vendor="ExampleVendor",
        product="ExampleProduct",
        version="v2.1.3",
        serviceAddress="127.0.0.1"
    )

def create_vulnerability_example():
    """
    Demonstrates how to create a Vulnerability object, which can be attached
    to an ImportAsset for vulnerability information tracking.

    Returns:
        Vulnerability: a populated Vulnerability object
    """
    return Vulnerability(
        id="vuln-789",
        name="CVE-1234-5678",
        description="Example vulnerability",
        cve="CVE-1234-5678",
        solution="Update to the latest patch",
        severityRank=4,          # 0=Info, 1=Low, 2=Med, 3=High, 4=Critical
        severityScore=10.0,
        riskRank=4,
        riskScore=10.0
    )


# ---------------
# json library
# ---------------
def example_json_usage():
    """
    Demonstrates how to use the json library for encoding and decoding.
    """
    sample_data = {"key": "value", "numbers": [1, 2, 3]}
    # Encode Python/Starlark dict to JSON string
    encoded = json_encode(sample_data)
    print("JSON-encoded data:", encoded)

    # Decode back to a Starlark/Python object
    decoded = json_decode(encoded)
    print("JSON-decoded data:", decoded)
    return decoded


# --------------
# net library
# --------------
def example_ip_usage():
    """
    Demonstrates how to parse an IP address using the net library.
    Returns a net.ip_address object (either IPv4 or IPv6).
    """
    addr_string = "192.168.10.55"
    ip_obj = ip_address(addr_string)
    print("IP version:", ip_obj.version)
    print("Compressed representation:", ip_obj.compressed)
    return ip_obj


# ---------------
# http library
# ---------------
def example_http_usage():
    """
    Demonstrates usage of the http library to construct a URL-encoded
    parameter set, then perform a GET request.
    """
    params = {"search": "alive:t", "limit": 10}
    encoded_params = url_encode(params)
    print("Encoded GET parameters:", encoded_params)

    # This is just a sample. If you hit a real URL, you'd typically do:
    #   response = get(url="https://example.com/api", params=params)
    #   or
    #   response = post(url="https://example.com/api", body=...)
    # For this demo, we'll just return the encoded_params
    return encoded_params


# ---------------
# uuid library
# ---------------
def example_uuid_usage():
    """
    Demonstrates how to use the uuid library to generate a unique ID.
    """
    unique_id = new_uuid()
    print("Generated UUID:", unique_id)
    return unique_id


# -------------
# main function
# -------------
def main(*args, **kwargs):
    """
    Main function that demonstrates capturing parameters from kwargs
    and printing a simple welcome message.

    Example usage in runZero:
        def main(*args, **kwargs):
            client_id = kwargs['access_key']
            client_secret = kwargs['access_secret']
            # Do something with client_id, client_secret
    """
    # For demonstration:
    if "access_key" in kwargs:
        client_id = kwargs["access_key"]
    if "access_secret" in kwargs:
        client_secret = kwargs["access_secret"]

    print("welcome to runZero custom integrations")

    # If needed, you can call any of the example functions here:
    # decoded = example_json_usage()
    # ip_obj = example_ip_usage()
    # new_id = example_uuid_usage()
    # params = example_http_usage()
    # asset = create_asset_example()
    # software = create_software_example()
    # vuln = create_vulnerability_example()
    # ...
