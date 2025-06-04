# Custom Integration: Invicti Enterprise

## runZero requirements

- Superuser access to the [Custom Integrations configuration](https://console.runzero.com/custom-integrations).

## Invicti Enterprise requirements

- User ID and API token for the Invicti Enterprise API.
- API endpoint: `https://www.netsparkercloud.com/api/1.0/issues/list`.

## Steps

1. (OPTIONAL) Modify the script as needed.
2. Create a Credential in runZero using your Invicti User ID as `access_key` and API token as `access_secret`.
3. Create a Custom Integration and paste the script.
4. Schedule the integration task and run it from an Explorer that can reach the Invicti API.

### What's next?

- The task will import vulnerabilities grouped by website root URL.
- Search for assets imported by this integration with `custom_integration:invicti-enterprise`.
