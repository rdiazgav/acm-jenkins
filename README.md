# Hello ACS Demo

A deliberately vulnerable but non-root Node.js app, used to demonstrate scanning with **Red Hat Advanced Cluster Security (ACS)**.

## Features

- Runs as **non-root** (UID 1001)
- Based on **UBI9 minimal**
- Uses **outdated dependencies** (`express@4.17.1`, `lodash@4.17.19`) to trigger CVEs: CVE-2022-24999, CVE-2021-23337
  
