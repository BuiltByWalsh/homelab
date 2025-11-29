# Homelab

![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Portainer](https://img.shields.io/badge/portainer-%2313BEF9.svg?style=for-the-badge&logo=portainer&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![Nginx Proxy Manager](https://img.shields.io/badge/nginx_proxy_manager-%23F15833.svg?style=for-the-badge&logo=nginxproxymanager&logoColor=white)
![Jellyfin](https://img.shields.io/badge/jellyfin-%23000B25.svg?style=for-the-badge&logo=Jellyfin&logoColor=00A4DC)
![Bash Script](https://img.shields.io/badge/bash_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

A homelab / home media server configuration powered by docker, nginx, and tailscale

> [!IMPORTANT]
> Project setup assumes a debian environment, adjust as needed for other linux distributions. 

## Pre-requisites 🛠️
1. Install docker for debian.
2. Install the tailscale service on the machine following the steps below.
3. Create a dotenv file to setup docker paths to your homelab media & content:
    ```sh
    touch .env && echo "DRIVE_POOL_DATA=/zdata" >> .env
    ```

    * Please tweak `DRIVE_POOL_DATA` in `.env` with the desired drive pool name accordingly.
    * Not sure where to start with filesystem configuration? `zfs`, `OpenZFS`, or `btrfs` are great options.
    * It is heavily encouraged to run a RAID configuration or RAIDZ for data integrity and loss prevention.
4. _**Optional**_: Secure a private cloud domain via your favorite domain registrar. It's recommended you use cloudflare or Namecheap as they provide developer API tokens we will use below.
    - If you're perfectly happy using IP addresses, skip this step. 

### Tailscale Guide
1. Follow the [linux tailscale install guide](https://tailscale.com/kb/1031/install-linux).
2. Because this is a home server, [disable key expiry](https://tailscale.com/kb/1028/key-expiry) in the tailscale admin console.
3. _(optional)_ Setup [Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh).

## What's Inside ✨

All services provided are managed by docker & portainer.

### Services Included

- [Portainer](http://localhost:9443)
- [Nginx Proxy Manager](http://localhost:81)
- [Jellyfin](http://localhost:8096)
- [Audiobookshelf](http://localhost:13378)
- [SyncThing](https://docs.syncthing.net/intro/getting-started.html#)

## Getting started 🚀

To startup services run:

```sh
sudo ./scripts/init.sh
```

To spin down services run:

```sh
sudo ./scripts/shutdown.sh
```

Each of these services should be available via your tailscale machines tailnet address, for example:
- `https:<yourtailscaleip>:9443` for portainer.
- `https:<yourtailscaleip>:81` for nginx.
- `https:<yourtailscaleip>:8096` for jellyfin.
- `https:<yourtailscaleip>:13378` for audiobookshelf.
- `https:<yourtailscaleip>:8384` for syncthing.

See steps below for configuring secure DNS and letsencrypt certificates for your homelab. 

## Configuring DNS 🌐

If you're happy using a tailnet IP addresses directly to manage homelab, you are done. If you want a more user-friendly experience with proper DNS handling, follow the guide below to configure DNS and SSL certificates. You will need to purchase a domain and be comfortable setting up DNS records. This guide assumes either a namecheap or cloudflare DNS provider for simplicities sake.

### DNS goals

---

> [!NOTE]
> This project takes an opinionated approach to DNS that follows a simple standard.

1. If you are on a device on your tailnet, you should be able to use services through a readable domain.
2. Each service should be configured using subdomains, e.g `https://portainer.yourprivate.cloud`, with a wildcard certificate.
3. **If you disconnect from the tailnet, you lose access to the homelab entirely**. In other words, we're setting up a DNS record that points to a tailscale IP, not something publicly available for all web traffic.

This approach is secure, gives total administrative control over to a tailscale admin, and should support common use cases like travel, where you can easily connect to your tailnet securely on public wifi.

### Setup proxy hosts in nginx

--- 

Open up Nginx Proxy Manager and follow these steps for each service you want exposed via your domain:
1. Navigate to proxy hosts in nginx.
2. Click Add Proxy Host.
3. Setup the source as `<service>.<yourdomain>.<yourtld>`, eg. `portainer.myprivatecloud.com`.
4. Setup the destination as localhost + the localhost docker port, eg. `127.0.0.1:8096` for jellyfin.
4. Set Access List to `Publicly Accessible`.
5. Turn on `Block Common Exploits` _(in practice this shouldn't matter because services run on a secure tailnet, but adds extra protections)_.
6. Add the SSL certificate from the "Configuring SSL certificates" step below. If this is a first time setup, ignore this step for now, you can add the SSL certificate later.

---

### Configuring DNS records
You will need your tailscale homelab machines tailnet IP address. You can find this in the tailscale admin console in a dropdown under `Machines`.
1. Add an `A Record` with `Host` set to `@` and `Value` set to the tailnet IP.
2. Add an `A Record` with `Host` set to `www` and `Value` set to the tailnet IP.
3. Add an `A Record` with `Host` set to `*` _(wildcard for subdomains)_ and a `Value` set to the tailnet IP.
    - This will help us capture the subdomains setup in the previous step with  nginx.
4. You should now be able to access services setup in nginx proxy. For example `https://portainer.yourprivatecloud.com`.

> [!WARNING]
> At this stage the browser will warn you that the connection is insecure. Please bypass browser security checks for now to verify nginx proxies are configured correctly. Configure SSL certificates below.

### Configuring an SSL certificate

---

Nginx Proxy Manager is setup to use `letsencrypt` by default. Below are some steps to create a wildcard SSL certificate directly in nginx proxy manager for free.

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

### Configuring Nginx Proxy Manager

Below is a list of sensible defaults you may use when configuring nginx proxy manager to work with the SSL certificates above:

| Source | Destination | SSL | Access |
| ------ | ----------- | --- | ------ |
| abs.jsquared.cloud | http://127.0.0.1:13378 | Let's Encrypt | Public |
| jellyfin.jsquared.cloud | http://127.0.0.1:8096 | Let's Encrypt | Public |
| portainer.jsquared.cloud | http://127.0.0.1:9443 | Let's Encrypt | Public |
| syncthing.jsquared.cloud | http://127.0.0.1:8384 | Let's Encrypt | Public |

Configure these proxy records as follows:

1. Select the certificate made in the `Configuring DNS` script up above.
2. Turn on `Force SSL` in the `Edit -> SSL` option.
3. Turn on `Websockets Support` for both jellyfin and abs _(audiobookshelf)_.
4. _**Optional**_: Configure `Block Common Exploits` on all records in `Edit -> Details`.
5. Test the connection in the browser by navigating to `https://portainer.yourprivatecloud.com`. The connection should now be encrypted.

## Syncthing

Syncthing comes out of the box with 4 directories:
  - `documents` - google drive / icloud drive / onedrive alternative.
  - `archive` - for storing large zips for backups, or exports _(say you request your data from a platform before deleting an account, or a GDPR request, etc)_
  - _**Optional**_: `obsidian` - an obsidian sync alternative.
  - _**Optional**_: `.task` a directory for syncing [taskwarrior](https://taskwarrior.org/) tasks across devices.
  
Comment out the mounted volumes in the syncthing docker compose service that you do not plan on using.


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

