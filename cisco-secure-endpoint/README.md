# Custom Integration: Cisco Secure Endpoint

## runZero requirements

- Superuser access to the [Custom Integrations configuration](https://console.runzero.com/custom-integrations) in runZero.

## Cisco Secure Endpoint requirements

- Client ID and Client Secret with API access.
- Cisco Secure Endpoint API URL (e.g. `https://api.amp.cisco.com`).

## Steps

### Cisco Secure Endpoint configuration

1. Obtain the Client ID and Client Secret from the Cisco Secure Endpoint console.
2. Note the API URL for your region.

### runZero configuration

1. (OPTIONAL) - make any necessary changes to the script to align with your environment.
    - Modify API queries as needed to filter data.
    - Modify datapoints uploaded to runZero as needed.
2. [Create the Credential for the Custom Integration](https://console.runzero.com/credentials).
    - Select the type `Custom Integration Script Secrets`.
    - For the `access_key`, input your Client ID.
    - For the `access_secret`, input your Client Secret.
3. [Create the Custom Integration](https://console.runzero.com/custom-integrations/new).
    - Add a Name and Icon for the integration (e.g., `cisco-secure-endpoint`).
    - Toggle `Enable custom integration script` to input your finalized script.
    - Click `Validate` to ensure it has valid syntax.
    - Click `Save` to create the Custom Integration.
4. [Create the Custom Integration task](https://console.runzero.com/ingest/custom/).
    - Select the Credential and Custom Integration created in steps 2 and 3.
    - Update the task schedule to recur at the desired timeframes.
    - Select the Explorer you'd like the Custom Integration to run from.
    - Click `Save` to kick off the first task.

### What's next?

- You will see the task kick off on the [tasks](https://console.runzero.com/tasks) page like any other integration.
- The task will update the existing assets with the data pulled from Cisco Secure Endpoint.
- The task will create new assets when there are no existing assets that meet merge criteria.
- You can search for assets enriched by this custom integration with the runZero search `custom_integration:cisco-secure-endpoint`.
