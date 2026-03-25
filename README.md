# DNS Zone Audit

A lightweight Bash-based security tool for testing DNS zone transfer misconfigurations (AXFR), associated with CVE-1999-0532.

This script queries authoritative name servers for a domain and attempts full zone transfers. If successful, it indicates a critical DNS misconfiguration that can expose internal infrastructure and records.

---

## Features

* Interactive domain input (single or multiple targets)
* Batch scanning via file input
* Automatic authoritative name server discovery
* AXFR testing over TCP
* Clear, color-coded output
* Minimal dependencies

---

## Requirements

* `bash`
* `dig` (from `dnsutils` or `bind-utils`)

### Install dependencies

**Debian / Ubuntu**

```bash
sudo apt install dnsutils
```

**RHEL / CentOS**

```bash
sudo yum install bind-utils
```

---

## Usage

### Run the script

```bash
git clone https://github.com/SleepTheGod/dns-zone-audit/
cd dns-zone-audit
chmod +x main.sh
./main.sh
```

### Input options

#### 1. Single or multiple domains

```text
example.com test.com target.org
```

#### 2. File input

```text
file:domains.txt
```

Example `domains.txt`:

```text
example.com
test.com
# comment line
target.org
```

---

## How It Works

1. Retrieves NS records for each domain
2. Iterates through each authoritative name server
3. Attempts a DNS zone transfer (AXFR)
4. Reports

   * SUCCESS → Zone transfer allowed (vulnerable)
   * FAILED → Transfer refused (secure)

---

## Example Output

```text
=== Testing domain: example.com ===
Name servers
  ns1.example.com
  ns2.example.com

Attempting zone transfer from ns1.example.com...
FAILED: Zone transfer refused or not allowed

Attempting zone transfer from ns2.example.com...
SUCCESS: Zone transfer allowed
```

---

## Security Impact

If a zone transfer succeeds, an attacker can retrieve

* Subdomains
* Internal hostnames
* Mail servers
* Infrastructure mapping

This significantly lowers the barrier for further attacks.

---

## Mitigation

To prevent unauthorized zone transfers

* Restrict AXFR to trusted IP addresses only
* Disable zone transfers if not required
* Use TSIG authentication between DNS servers

---

## Disclaimer

This tool is intended for **authorized security testing only**.

Do not use it against systems you do not own or have explicit permission to assess. Unauthorized testing may be illegal.

---

## Author

Taylor Christian Newsome
