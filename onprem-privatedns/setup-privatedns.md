

````markdown
# Private BIND DNS Server Setup on Ubuntu 22.04

This repository contains instructions and example configurations to set up a **private BIND 9 DNS server** on Ubuntu 22.04 for an internal domain `selise.internal`.

---

## Overview

- DNS Server IP: `172.16.2.8` (`bindserver`)
- Domain: `selise.internal`
- Clients:
  - `random` — `172.16.2.146`
  - `modsec` — `172.16.2.235`
- Supports forward and reverse DNS lookups within the LAN subnet `172.16.2.0/24`

---

## Prerequisites

- Three Ubuntu 22.04 machines on the same subnet (`172.16.2.0/24`)
- Root or sudo access on all machines

---

## Step 1: Update All Machines

```bash
sudo apt update -y && sudo apt upgrade -y
````

---

## Step 2: Install BIND on DNS Server (`bindserver`)

```bash
sudo apt install bind9 bind9utils bind9-doc -y
sudo systemctl status bind9
```

---

## Step 3: Configure BIND Server

### 3.1: Edit `/etc/bind/named.conf.options`

```conf
acl LAN {
    172.16.2.0/24;
};

options {
    directory "/var/cache/bind";
    allow-query { localhost; LAN; };
    forwarders { 1.1.1.1; };
    recursion yes;
};
```

Validate:

```bash
sudo named-checkconf /etc/bind/named.conf.options
```

---

### 3.2: Edit `/etc/bind/named.conf.local`

```conf
zone "selise.internal" IN {
    type master;
    file "/etc/bind/zones/selise.internal";
};

zone "2.16.172.in-addr.arpa" IN {
    type master;
    file "/etc/bind/zones/selise.internal.rev";
};
```

Validate:

```bash
sudo named-checkconf /etc/bind/named.conf.local
```

---

### 3.3: Create Zones Directory

```bash
sudo mkdir -p /etc/bind/zones
```

---

### 3.4: Create Forward Zone `/etc/bind/zones/selise.internal`

```conf
$TTL 604800
@       IN      SOA     selise.internal. root.selise.internal. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

@       IN      NS      bindserver.selise.internal.

bindserver      IN      A       172.16.2.8
random          IN      A       172.16.2.146
modsec          IN      A       172.16.2.235
```

Validate:

```bash
sudo named-checkzone selise.internal /etc/bind/zones/selise.internal
```

---

### 3.5: Create Reverse Zone `/etc/bind/zones/selise.internal.rev`

```conf
$TTL 604800
@       IN      SOA     selise.internal. root.selise.internal. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

@       IN      NS      bindserver.selise.internal.

bindserver      IN      A       172.16.2.8

8       IN      PTR     bindserver.selise.internal.
146     IN      PTR     random.selise.internal.
235     IN      PTR     modsec.selise.internal.
```

Validate:

```bash
sudo named-checkzone 2.16.172.in-addr.arpa /etc/bind/zones/selise.internal.rev
```

---

### 3.6: Restart BIND

```bash
sudo systemctl restart bind9
sudo systemctl status bind9
```

---

## Step 4: Configure Clients (`random`, `modsec`)

### 4.1: Identify Interface

```bash
ip a
```

### 4.2: Edit Netplan Config (example for `modsec`)

Edit `/etc/netplan/00-installer-config.yaml`:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 172.16.2.235/24
      gateway4: 172.16.2.1
      nameservers:
        addresses:
          - 172.16.2.8
        search:
          - selise.internal
```

Apply changes:

```bash
sudo netplan apply
```

---

## Step 5: Verify DNS Resolution on Clients

```bash
nslookup bindserver.selise.internal
nslookup random.selise.internal
nslookup modsec.selise.internal

nslookup 172.16.2.8
nslookup 172.16.2.146
nslookup 172.16.2.235

ping modsec.selise.internal
ping random.selise.internal
```

---

## Troubleshooting

* Check BIND status and logs:

```bash
sudo systemctl status bind9
journalctl -u bind9
```

* Verify configuration syntax:

```bash
sudo named-checkconf
sudo named-checkzone <zone> <zonefile>
```

* On clients, ensure `/etc/resolv.conf` points to your DNS server IP (`172.16.2.8`).

* Restart `systemd-resolved` if DNS doesn't update:

```bash
sudo systemctl restart systemd-resolved
```
---

## Author

Adil Reza
