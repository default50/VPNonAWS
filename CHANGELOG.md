# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This is Infrastructure-as-Code for a self-hosted WireGuard VPN on AWS (CloudFormation +
a bash deploy script). "Versions" here mark meaningful milestones in the infrastructure
and tooling rather than a shipped software artifact.

## [Unreleased]

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
