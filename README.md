# Homelab

A homelab / home media server configuration powered by docker, nginx, and tailscale

> [!IMPORTANT]
> Project setup assumes a debian environment, adjust as needed for other linux distributions. 

## Pre-requisites
1. Install docker for debian.
2. Install the tailscale service on the machine following the steps below.
3. _Optional_ secure a private cloud domain via your favorite domain registrar. It's recommended you use cloudflare or Namecheap as they provide developer API tokens we will use below.
    - If you're perfectly happy using IP addresses, skip this step. 

### Tailscale Guide
1. Follow the [linux tailscale install guide](https://tailscale.com/kb/1031/install-linux).
2. Because this is a home server, [disable key expiry](https://tailscale.com/kb/1028/key-expiry) in the tailscale admin console.
3. _(optional)_ Setup [Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh).

## What's Inside
All services provided by this server are managed via docker & portainer.

## Services

- [Portainer](http://localhost:9443)
- [Reverse Proxy via Nginx Proxy Manager](http://localhost:81)
- Jellyfin
- Audioshelf

## Getting started

To startup services run

```sh
sudo ./scripts/init.sh
```
Each of these services should be available via your tailscale machines tailscale address, for example:
- `https:<yourtailscaleip>:9443` for portainer
- `https:<yourtailscaleip>:81` for nginx.

See steps below for configuring secure DNS and letsencrypt certificates for your homelab. 

## Configuring DNS

If you're happy using tailnet IP addresses directly to manage homelab, you are done. If you want a more user-friendly experience with proper DNS handling, follow the steps below to configure DNS and SSL certificates.You will need to purchase a domain and be comfortable setting up DNS records as specified below. I recommend using namecheap or Cloudflare.

This project takes an opinionated approach to DNS that follows a simple standard.

1. If you are on a device on your tailnet, you should be able to use services through human readable domain names.
2. Each service should be configured using subdomains, e.g `https://portainer.yourprivate.cloud`.
3. If you are not on your tailnet, you have access to nothing. In other words, we're setting up a DNS record that points to a tailscale IP, not something publically available for all web traffic.

This approach is secure, gives total administrative control over to a tailscale admin, and should support common use cases like travel, where you can easily connect to your tailnet securely on public wifi.

### Setup proxy hosts in nginx proxy manager
Follow these steps for each service you want exposed via your domain.
1. Navigate to proxy hosts in nginx.
2. Click Add Proxy Host.
3. Setup the source as `<service>.<yourdomain>:<dockerport>`, eg. `portainer.myprivatecloud.com:9443`.
4. Set Access List to `Publically Accessible`.
5. Turn on `Block Common Exploits` (in practice this won't matter because services run on a secure tailnet, but adds extra protections).

### Configure DNS records.
You will need your tailscale homelab machines tailnet IP address. You can find this in the tailscale admin console in a dropdown under `Machines`.
1. Add an `A Record` with Host set to `@` and Value set to the tailnet IP.
2. Add an `A Record` with Host set to `www` and Value set to the tailnet IP.
3. Add an `A Record` with Hos set to `*` (wildcard) and a Value set to the tailnet IP.
    - This will help us capture subdomains which nginxproxy has setup as proxy hosts.
4. You should now be able to access services setup in nginx proxy. For example `https://portainer.yourprivatecloud.com`.
    - You will likely get an invalid certificate in the browser telling you the site is insecure. Bypass it for now to verify nginx proxies are working as expected. We will address this in the next step.

### Configuring SSL certificates

Nginx Proxy Manager is setup to use letsencrypt by default. Below are some steps to create SSL certificates directly in nginx proxy manager without paying a domain registrar extra for SSL.

1. Optain a developer API key from your DNS provider. For both namecheap and cloudflare, this will be under your profile settings.
2. If necessary, whitelist your homelabs public IP address so that it's available to make API requests.
3. In Nginx Proxy Manager, navigate to certificates and click `Add certificate`.
4. Select `Let's Encrypt via DNS`.
5. Use a wildcard for the certificate name, eg. `*.yourprivatecloud.com`.
6. Select your DNS provider in the dropdown menu, e.g namecheap or cloudflare, etc.
7. You will be prompted to provide the API token you obtained in step 1 for letsencrypt & cerbot to confirm DNS informaton with your provider.
8. Once you have a certificate, navigate back to your proxy hosts and setup every proxy host to use your new SSL certificate.
9. Navigate to one of your services via your domain, and ensure the connection is secure.
10. You will now use this wild card certificate on all new host records you setup from here on out.

