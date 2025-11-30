# Homelab

A homelab / home media server configuration

**Powered By**

![Debian Badge](https://img.shields.io/badge/Debian-A81D33?logo=debian&logoColor=fff&style=flat)
![Docker Badge](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=fff&style=flat)
![Portainer Badge](https://img.shields.io/badge/Portainer-13BEF9?logo=portainer&logoColor=fff&style=flat)
![NGINX Badge](https://img.shields.io/badge/NGINX-009639?logo=nginx&logoColor=fff&style=flat)
![Nginx Proxy Manager Badge](https://img.shields.io/badge/Nginx%20Proxy%20Manager-F15833?logo=nginxproxymanager&logoColor=fff&style=flat)

**Homelab Services**

![Jellyfin Badge](https://img.shields.io/badge/Jellyfin-00A4DC?logo=jellyfin&logoColor=fff&style=flat)
![Audiobookshelf Badge](https://img.shields.io/badge/Audiobookshelf-82612C?logo=audiobookshelf&logoColor=fff&style=flat)
![Syncthing Badge](https://img.shields.io/badge/Syncthing-0891D1?logo=syncthing&logoColor=fff&style=flat)

## Prerequisites 🛠️

> [!IMPORTANT]
> Project setup assumes a debian environment, adjust as needed for other linux distributions.

1. Install [docker for debian](https://docs.docker.com/engine/install/debian/).
2. Create a dotenv file to setup paths for the homelab drive pool directory as well as the desired service install path. Refer to the `.env.example`. Here are some recommendations:
    ```sh
    touch .env && echo $'DRIVE_POOL_DATA=/zdata' >> .env
    ```
    * Adjust the `DRIVE_POOL_DATA` directory to your desired drive pool accordingly.
    * Not sure where to start with filesystem configuration? `zfs`, `OpenZFS`, or `btrfs` are all great options.
    * It is heavily encouraged to run a `RAID5` or `RAIDZ1` setup for data integrity and loss prevention.
3. Install the tailscale service on the machine following the [Tailscale Guide](#tailscale-guide) below.
4. _**Optional (recommended)**_: Secure a domain for the homelab via your favorite domain registrar. It's recommended you use cloudflare or Namecheap as they provide developer API tokens we will use below.
    - If you're perfectly happy configuring and using static IP addresses, or using tailnet IP addresses, _skip this step_.

### Tailscale Guide
1. Follow the [linux tailscale install guide](https://tailscale.com/kb/1031/install-linux).
2. Because this is a home server, [disable key expiry](https://tailscale.com/kb/1028/key-expiry) in the tailscale admin console.
3. _(Optional)_ Setup [Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh).

## What's Inside ✨

All services provided are managed by docker & portainer.

### Services Included

- [Portainer](http://localhost:9443)
- [Nginx Proxy Manager](http://localhost:81)
- [Jellyfin](http://localhost:8096)
- [Audiobookshelf](http://localhost:13378)
- [SyncThing](https://docs.syncthing.net/intro/getting-started.html#)

## Getting started

- Clone the starter:
  ```sh
  git clone https://github.com/BuiltByWalsh/homelab ~/.config/homelab
  ```
- Remove the `.git` folder, so you can add it to your own repo later:
  ```sh
  rm -rf ~/.config/homelab/.git
  ```

- To startup services run:
  ```sh
  sudo ./scripts/init.sh
  ```

- To shutdown services run:
  ```sh
  sudo ./scripts/shutdown.sh
  ```

In addition to localhost, each of these services should be available via your tailscale homelab machine tailnet address, for example:
- portainer -> `https:<yourtailscaleip>:9443`
- nginx proxy manager admin UI -> `https:<yourtailscaleip>:81`.
- nginx proxy manager -> `https:<yourtailscaleip>` _(port 80)_.
- jellyfin -> `https:<yourtailscaleip>:8096`.
- audiobookshelf -> `https:<yourtailscaleip>:13378`.
- syncthing -> `https:<yourtailscaleip>:8384`.

See steps below for configuring DNS and and generating secure certificates for your homelab via `letsencrypt`.

## Configuring DNS 🌐

If you're happy using a tailnet IP addresses directly to manage homelab, [skip ahead to the Syncthing](#syncthing). If you want a more user-friendly experience with proper DNS handling, follow the guide below to configure DNS and SSL certificates. You will need to purchase a domain and be comfortable setting up DNS records. This guide assumes either a namecheap or cloudflare DNS provider for simplicity.

### DNS goals

---

> [!NOTE]
> This project takes an opinionated approach to DNS that follows a simple standard.

1. If you are on a device on your tailnet, you should be able to use services through a readable domain.
2. Each service should be configured using subdomains, e.g `https://portainer.yourdomain.cloud`, or `https://jellyfin.yourdomain.cloud`; using one singular wildcard certificate.
3. **If you disconnect from the tailnet, you lose access to the homelab entirely**. In other words, we're setting up a DNS record that points to your homelab tailscale IP, rather than something available to service public web traffic.

This approach is secure, private by default, and gives total administrative control over to the tailscale admin. This setup should support common use cases like travel, streaming on public wifi, and accessing data over 5G cellular, so long as you have an [exit node](https://tailscale.com/kb/1103/exit-nodes) setup.

---

### Configuring DNS records
You will need your homelab machine tailnet IP address. You can find this in the tailscale admin console on the `Machines` tab by clicking on the `Addresses` dropdown menu for your homelab machine.
1. Add an `A Record` with `Host` set to `@` and `Value` set to the tailnet IP.
2. Add an `A Record` with `Host` set to `www` and `Value` set to the tailnet IP.
3. Add an `A Record` with `Host` set to `*` _(wildcard for subdomains)_ and a `Value` set to the tailnet IP.
    - This will help us capture the subdomains we'll setup when [configuring Nginx Proxy Manager](#configuring-nginx-proxy-manager) below.
4. You should now be able to access Nginx Proxy Manager by navigating to your new domain.

> [!WARNING]
> At this stage the browser may warn you that the connection is insecure. Please bypass browser security checks for now to verify your DNS records are configured to correctly hit Nginx Proxy Manager. Configure SSL certificates below.

### Configuring an SSL certificate

---

Nginx Proxy Manager is setup to use `letsencrypt` by default. Below are some steps to create a wildcard SSL certificate directly in Nginx Proxy Manager for free.

1. Optain a developer API key from your DNS provider. For both Namecheap and Cloudflare, this will be under your profile settings.
2. If necessary, whitelist your homelabs public IP address so that it's available to make API requests.
3. In Nginx Proxy Manager, navigate to certificates and click `Add certificate`.
4. Select `Let's Encrypt via DNS`.
5. Use a wildcard for the certificate name, eg. `*.yourprivatecloud.com`.
6. Select your DNS provider in the dropdown menu, e.g Namecheap or Cloudflare, etc.
7. You will be prompted to provide the API token you obtained in step 1 for `letsencrypt` & `certbot` to confirm domain ownership and metadata with your DNS provider.
8. Hit `Save`.
9. Going forward, select this wild card certificate on all new nginx proxy host records going forward.
10. Navigate back to proxy hosts and configure each proxy host record to use the new certificate following the steps below.

---

### Configuring Nginx Proxy Manager

Below is a list of sensible defaults you may use when configuring service subdomains proxies using the the SSL certificate generated in the previous step:

| Source                          | Destination            | SSL           | Access |
| ------------------------------- | ---------------------- | ------------- | ------ |
| audiobookshelf.yourdomain.cloud | http://127.0.0.1:13378 | Let's Encrypt | Public |
| jellyfin.yourdomain.cloud       | http://127.0.0.1:8096  | Let's Encrypt | Public |
| portainer.yourdomain.cloud      | http://127.0.0.1:9443  | Let's Encrypt | Public |
| syncthing.yourdomain.cloud      | http://127.0.0.1:8384  | Let's Encrypt | Public |

Configure these proxy records as follows:
1. Click the `Add proxy host` button and navigate to the `Details` tab.
2. Attach the proper subdomain.
3. Set `Scheme` to `http` *(local docker traffic is not encrypted)*.
4. Set `Forward Hostname / IP` to `127.0.0.1`.
5. Set `Forward Port` to the port for that specific service *(see table above)*.
6. Toggle `Block Common Exploits`.
7. Toggle `Websockets Support` for jellyfin, audiobookshelf, and syncthing.
8. Navigate to the `SSL` tab.
9. Select the `letsencrypt` certificate from generated during [configuring an SSL certificate](#configuring-an-ssl-certificate) step up above.
10. Toggle `Force SSL`.

Test the connection in the browser by navigating to `https://portainer.yourdomain.cloud`. The connection should now be secure.

## Syncthing

Synchronize your documents across devices using peer-to-peer connections.

The Syncthing docker service comes out of the box with 4 directories:
  - `/documents` - google drive / icloud drive / one drive alternative.
  - `/archive` - for storing large zips for backups, or data exports _(e.g a 7zip dump)_.
  - _**Optional**_: `/obsidian` - a mechanism for setting up obsidian sync all on your own.
  - _**Optional**_: `/taskwarrior` a directory for syncing [taskwarrior](https://taskwarrior.org/) tasks across devices.
    -  On local devices sync `/taskwarrior` back to `~/.task`. By default the `syncthing` docker container _**does not**_ run with administrator priveleges, which means on the homelab data pool cannot be the traditional `~/.task` hidden directory.

> [!TIP]
> _Remove / comment out any unnecessary volumes in the syncthing docker compose service._

Congratulations on the new homelab 👏. Happy tinkering.

## Create a systemd service

To create a system-wide service for running the homelab you can reference `.examples/homelab.service.example` as a starting point.

1. Copy the content in `.examples/homelab.service.example` to `/etc/systemd/system/homelab.service`.
    > [!Important]
    >  You must replace `<INSERT_USERNAME>` from the example with your actual Linux username *(e.g. the user associated with the home directory where you cloned the repository)*.

2. Run the following:
    ```sh
    # Reload the systemd daemon to recognize the new file
    sudo systemctl daemon-reload
    # Enable the service to start at boot and start it immediately
    sudo systemctl enable --now homelab.service
    ```
3. To stop and restart the service:
    ```sh
    sudo systemctl stop homelab.service
    sudo systemctl start homelab.service
    ```


## Resources & documentation 📚

- [Portainer](https://docs.portainer.io/)
- Nginx
  - [Nginx Proxy Manager](https://nginxproxymanager.com/guide/)
  - [Nginx Proxy Manager Subreddit](https://www.reddit.com/r/nginxproxymanager/)
- Tailscale
  - [Tailscale Daemon](https://tailscale.com/kb/1278/tailscaled)
  - [Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh?q=ssh)
  - [Tailscale Key Expiry](https://tailscale.com/kb/1028/key-expiry?q=expiry)
- Services
    - [Jellyfin](https://jellyfin.org/docs/general/installation/container/)
    - [Audiobookshelf](https://www.audiobookshelf.org/docs/#docker-compose-install)
    - [SyncThing](https://docs.syncthing.net/intro/getting-started.html)
- Useful forums:
  - [/r/selfhosted](https://www.reddit.com/r/selfhosted/)
  - [r/tailscale](https://www.reddit.com/r/selfhosted/)

