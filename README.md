# VPNonAWS

A simple way to stand up your own [WireGuard](https://www.wireguard.com/) VPN
endpoints on AWS. Each endpoint is a self-contained CloudFormation stack — a VPC,
a single EC2 instance running WireGuard, an Elastic IP, and an optional Route53
record — so you can bring a VPN exit point online in a region with one deploy and
tear it down just as easily.

Deploy the same stack to as many regions as you like to choose your exit location,
using the included `deploy.sh` wrapper (multi-region prompts and change-set previews
before anything is applied).

## Features

- **Multi-region, one client config.** Deploy the same stack to any AWS region; every
  endpoint shares the same WireGuard peer keys, so a single client configuration connects
  to any of them. Switch endpoints to change your exit location.
- **Always-current base image.** The EC2 AMI is resolved at deploy time from the SSM public
  parameter for the latest Amazon Linux 2023 (arm64 / Graviton) — there's no hardcoded AMI
  list to go stale.
- **Self-contained per region.** Each stack builds its own VPC, subnet, Elastic IP, security
  group, and instance, plus an optional friendly Route53 record. Bring one up or tear it down
  without touching the others; the Elastic IP keeps the address (and DNS) stable across stops.
- **Private DNS resolver.** An on-box [unbound](https://www.nlnetlabs.nl/projects/unbound/)
  recursive resolver serves VPN clients, so DNS lookups go through the tunnel instead of a
  third-party resolver.
- **Sensible defaults baked in.** IMDSv2 is required on the instance, `nftables` handles NAT
  and forwarding, and up to six named peers are configured straight from stack parameters.

## How it works

Each region is a single CloudFormation stack: a VPC with a public subnet, an Elastic IP, a
security group, and one Graviton (arm64) EC2 instance. On first boot, `cfn-init` builds
WireGuard from source on Amazon Linux 2023, configures `nftables` masquerading and IP
forwarding, and starts `unbound` as the resolver. Peers are rendered into the WireGuard
config from stack parameters (up to six), and the optional Route53 A record gives the
endpoint a friendly name like `wireguard.<region>.example.com`.

## Project tracking

- Planned work and candidate ideas live in [`BACKLOG.md`](BACKLOG.md).
- Notable changes are recorded in [`CHANGELOG.md`](CHANGELOG.md).
