# RDP2: Cloud-Native Remote Development Environments

RDP2 provides secure, ephemeral, and persistent Windows-based remote development environments leveraging GitHub Actions runners. It is designed for developers who need a powerful, cloud-hosted workstation accessible from anywhere via a private VPN.

## 🚀 Features

- **Ephemeral & Secure**: Runners are provisioned on-demand using GitHub-hosted `windows-2025` infrastructure.
- **Private Access**: Connectivity is established via **Tailscale Mesh VPN**, ensuring RDP is never exposed to the public internet.
- **Persistence**: Workspaces persist state (projects, browser profiles, Android Studio configurations) using GitHub Actions Cache.
- **Pre-configured Tools**: Automated installation of VS Code, Firefox, Git, JDK 21, Android Studio, Node.js, and more via Winget.
- **Customizable**: Workflows allow for dynamic selection of Node.js versions, Java versions, SSH default shells, and additional software packages.

## 🏗️ Architecture

1.  **Orchestrator**: GitHub Actions triggers the provisioning workflow.
2.  **Host**: A `windows-2025` runner is allocated.
3.  **Network**: Tailscale connects the runner to your private mesh network.
4.  **Storage**: The `D:` drive is initialized and mapped to persistent caches.
5.  **Provisioning**: PowerShell scripts configure RDP, firewall rules, and install developer tools.
6.  **Lifecycle**: A "Maintain Connection" loop keeps the runner alive until a manual signal or timeout (up to 350 minutes).

## 🛠️ Prerequisites

Before running the workflows, ensure you have configured the following:

### 1. Tailscale Setup
- Create a [Tailscale](https://tailscale.com/) account.
- Generate an **Auth Key** from the Tailscale Admin Console (Settings > Keys). It is recommended to use a "Reusable" and "Ephemeral" key.

### 2. GitHub Secrets
Add the following secrets to your repository (`Settings > Secrets and variables > Actions`):

| Secret | Description |
| :--- | :--- |
| `TAILSCALE_AUTH_KEY` | Your Tailscale Auth Key for VPN connectivity. |
| `RDP_PASS` | (Optional for `rdp.yml`) The password for the RDP user. |

## 📖 Usage

1.  Navigate to the **Actions** tab in your repository.
2.  Select a workflow:
    - **Chill**: Highly customizable environment with input parameters.
    - **RDP-Development-Environment**: A standard, pre-configured environment.
3.  Click **Run workflow**.
4.  Once the workflow reaches the "Maintain Connection" step, connect to the provided **Tailscale IP** using an RDP client (e.g., Microsoft Remote Desktop).
5.  **Important**: To save your work, use the **"Save and Exit"** shortcut on the desktop before closing the RDP session.

## 🛡️ Security

- RDP is restricted to the Tailscale IP range (`100.64.0.0/10`).
- Use strong passwords and manage your Tailscale ACLs to restrict access further.
