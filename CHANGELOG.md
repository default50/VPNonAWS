# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This is Infrastructure-as-Code for a self-hosted WireGuard VPN on AWS (CloudFormation +
a bash deploy script). "Versions" here mark meaningful milestones in the infrastructure
and tooling rather than a shipped software artifact.

## [Unreleased]

## [1.1.0] - 2026-08-25

### Added

- `InstanceRole` (`AWS::IAM::Role` with the `AmazonSSMManagedInstanceCore` managed policy, plus an
  inline policy granting `cloudformation:DescribeStackResource`/`SignalResource` — needed once a
  profile is attached, otherwise `cfn-init` can no longer read its metadata) and `InstanceProfile`,
  attached to the WireGuard instance so SSM Session Manager works as a first-class, IaC-managed
  admin path. This replaces the out-of-band `AmazonSSMRoleForInstancesQuickSetup` profile the
  running instances carried.

### Changed

- Locked down SSH ingress: removed the `TCP 22 from 0.0.0.0/0` rule from the WireGuard security
  group. The tunnel (UDP `ServerPort`) is now the only inbound port. Admin access moves to SSM
  Session Manager, which needs no open port.

### Removed

- The `KeyName` parameter and the instance's SSH key pair, fully committing admin access to SSM.
  Note: `KeyName` is `UpdateRequires: Replacement`, so deploying this replaces the EC2 instance in
  each region. The EIP stays associated and the DNS A record is static, so the public IP and
  hostname survive the replacement; expect ~10-15 minutes of downtime per region while the new
  instance runs `cfn-init` and rebuilds WireGuard from the (unchanged) stack parameters.

### Fixed

- Bootstrap on the 512 MB `t4g.nano` for current AL2023 AMIs: create the swap file at the top of
  UserData (before the first `yum`) and size it at 2 GB, guard the redundant `aws-cfn-bootstrap`
  install (it ships preinstalled on AL2023), and raise the `CreationPolicy` timeout to 20 minutes.
  Newer AL2023 first-boot `dnf` swap-thrashes on 512 MB, stretching the bootstrap to ~10-15
  minutes; without these the instance OOM-killed `yum` (or timed out) and the deploy rolled back.

## [1.0.1] - 2026-08-23

### Removed

- The OpenVPN path, retired for good: deleted `openvpn-aws.template.yaml` and `OpenVPN-AMIs.sh`,
  and removed the stale `openvpn_improvements` branch. WireGuard is now the only VPN option.

## [1.0.0] - 2026-08-23

First tagged release. Establishes the repo's tooling and documentation baseline around the
existing WireGuard-on-AWS CloudFormation templates and `deploy.sh`.

### Added

- `.githooks/pre-commit` — lints all root-level `*.template.yaml` with `cfn-lint` and all tracked
  `*.md` with `markdownlint-cli2` before every commit; blocks on findings. Enable per clone with
  `git config core.hooksPath .githooks`.
- `.markdownlint.jsonc` — markdownlint config (relaxes MD013 line-length and MD024 to
  siblings-only for the repeating CHANGELOG headings).
- `BACKLOG.md` and `CHANGELOG.md` — in-repo work tracking (replaces the ad-hoc README ToDo list).
- `README.md` overview — what the repo does, a features list, and a short "how it works".
- `LICENSE` — MIT license, so the public repo has clear reuse terms (GitHub derives the license
  badge from this file).

### Changed

- `.gitignore` now excludes `.kiro/`, keeping internal steering context out of this public repo.

### Removed

- Redundant `DependsOn: IPAddress` on `OpenVPNInstance` in `openvpn-aws.template.yaml`
  (`cfn-lint` W3005 — the dependency is already implied by the `${IPAddress}` `Ref` in UserData).
  Cleared the one lint finding so the new pre-commit hook passes.

[Unreleased]: https://github.com/default50/VPNonAWS/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/default50/VPNonAWS/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/default50/VPNonAWS/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/default50/VPNonAWS/releases/tag/v1.0.0
