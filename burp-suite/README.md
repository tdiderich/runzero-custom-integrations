# Custom Integration: Burp Suite Enterprise Edition

## runZero requirements

- Superuser access to the [Custom Integrations configuration](https://console.runzero.com/custom-integrations) in runZero.

## Burp Suite Enterprise Edition requirements

- API user with an API key.
- Base URL for your Burp Suite Enterprise server (e.g., `https://burp.example.com`).

## Steps

### Burp Suite configuration

1. Log in as an administrator.
2. Navigate to **Team > Add a new user** and choose **API key** as the login type.
3. Assign permissions and save the generated API key.
4. Note your Burp Suite server URL.

### runZero configuration

1. (OPTIONAL) Modify the script to fit your environment.
2. [Create the Credential](https://console.runzero.com/credentials).
   - Select `Custom Integration Script Secrets`.
   - Use the `access_key` field for your Burp Suite base URL.
   - Use the `access_secret` field for the API key.
3. [Create the Custom Integration](https://console.runzero.com/custom-integrations/new).
   - Add a Name and Icon (e.g., "burp-suite").
   - Toggle `Enable custom integration script` and paste the script.
   - Click `Validate` then `Save`.
4. [Create the Custom Integration task](https://console.runzero.com/ingest/custom/).
   - Select the Credential and Custom Integration created above.
   - Set the schedule and choose the Explorer to run from.
   - Click `Save` to kick off the first task.

### What's next?

- The task retrieves the list of sites from Burp Suite Enterprise Edition.
- For each site it gathers scan issues and adds them as vulnerabilities.
- Assets representing these sites will appear in runZero with the search `custom_integration:burp-suite`.
