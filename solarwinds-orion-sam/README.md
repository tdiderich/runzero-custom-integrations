# Custom Integration: SolarWinds Orion SAM

## runZero requirements

- Superuser access to the [Custom Integrations](https://console.runzero.com/custom-integrations) configuration.

## SolarWinds Orion requirements

- REST API access to the SolarWinds Information Service (SWIS).
- Username and password with permission to query Orion nodes.
- Base URL reachable by the runZero Explorer, e.g. `http://hostnameOrIPAddress:8787`.

## Credentials

Create a credential in runZero with these fields:

- `access_key`: SolarWinds username.
- `access_secret`: SolarWinds password.

## Steps

1. Create the credential as described above.
2. Create a new Custom Integration using the script in this directory.
3. Run an Ingest task selecting your credential and this integration.

## Search Syntax in runZero

To locate assets imported by this integration:

```
custom_integration:solarwinds-orion-sam
```
