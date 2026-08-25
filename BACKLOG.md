# Backlog

How this file works:

- **Active backlog** — work committed to doing. Tracked with `- [ ]` checkboxes.
- **Done** — shipped work, one line each. Full detail lives in `CHANGELOG.md` and git history;
  this section is just an index of what's settled.
- **Decisions on record** — settled tradeoffs worth not re-litigating.

## Active backlog

### Low priority

- [ ] **cfn-guard policy checks.** Layer `cfn-guard` on the existing `cfn-lint` pre-commit hook to
      enforce project rules (no unintended `0.0.0.0/0` ingress, IMDSv2 stays required). `cfn-lint`
      already covers validity, so this is additive — needs the binary plus rule files.
- [ ] **Migrate the UserData bash to cloud-init-native config.** Replace the imperative
      `#!/bin/bash` UserData (swap + install + invoke `cfn-init`) with cloud-init directives —
      still driving `cfn-init`, not replacing it. Modest upside: cloud-init's declarative `swap:`
      module provisions swap early in boot (could retire the manual UserData swap block and the
      `create_swap` configset), and it's tidier. No bootstrap-performance benefit. Ref:
      <https://cloudinit.readthedocs.io/en/latest/topics/examples.html>.

### Tooling

- [ ] **Purpose-built CLI to replace `deploy.sh`.** A small Python CLI (boto3) that supersedes
      the bash script: profile/region resolution (`--flag` > env > committed defaults),
      change-set-based deploys with replacement flagging, a read-only status command (caller
      identity + per-region stack/instance health), and `--dry-run` / `--yes` for a safe
      preview→apply loop with structured, greppable output. Would also make the multi-region
      iteration and the start/stop of the standby (GRU) instance first-class. Larger effort —
      `deploy.sh` is fine for now; this is a "when it's worth it" item. Could also include a
      `diagnose` subcommand (see Debuggability below): on a bootstrap signal-timeout, surface the
      off-box `cfn-init.log` and report the failing step.
- [ ] **Start/stop instances on demand (with optional auto-stop timeout).** Give the CLI a way to
      start or stop the WireGuard instances per region (or all at once) without a full deploy —
      handy for waking the standby (GRU) or parking idle regions to save cost. Bonus: start with a
      lease, e.g. `start --for 3h` (accept minutes/hours/days), so the instance auto-stops when the
      lease expires and nothing is left running by accident. Likely implemented with a tag the
      instance carries (`auto-stop-at=<timestamp>`) plus a scheduled sweeper (EventBridge Scheduler
      → a small Lambda, or an in-CLI `sweep` command run from cron) that stops instances whose lease
      has passed. EIP + DNS survive stop/start, so no address churn.

### Debuggability

Making failed instance bootstraps inspectable (a rollback terminates the instance and its
`cfn-init.log` with it). Preferred direction: ship logs off-box so debugging never depends on
catching a doomed instance.

- [ ] **Ship bootstrap logs off-box.** Push `cfn-init.log` / `cloud-init-output.log` to S3 or
      CloudWatch on failure (before `cfn-signal -e 1`) so evidence survives a rollback — no
      instance-catching, no scratch instance. Needs a small IAM add on the instance role plus a
      bucket/log group. (A `--disable-rollback` deploy flag would not help: CloudFormation rejects
      it for replacement updates, which is the failure mode that matters here.)

### Maintenance

- [ ] **Configure regular security updates.** The instance runs `yum update -y` once at bootstrap
      and then never patches (instances are long-lived — replacements are rare). Set up ongoing
      security patching. Evaluate the mechanism at implementation time (e.g. `dnf-automatic`, a
      scheduled SSM command / Patch Manager, or periodic AMI refresh + replace) rather than
      committing to one now. One reference option: <https://stackoverflow.com/a/46248515/1943898>.

## Done

Shipped work, newest first. Full detail in `CHANGELOG.md` + git history.

- **Lock down SSH ingress** (1.1.0) — dropped the `TCP 22 from 0.0.0.0/0` rule and the
  `KeyName` key pair from the WireGuard template; admin access is now SSM Session Manager, backed
  by a template-managed IAM role + instance profile. No open admin port. Deploying replaces the
  instances (`KeyName` change), but EIP + static DNS survive.
- **Retire OpenVPN entirely** (1.0.1) — deleted `openvpn-aws.template.yaml` and
  `OpenVPN-AMIs.sh`, and removed the stale `openvpn_improvements` branch. WireGuard is now the
  only VPN path.
- **Repo modernization** (1.0.0) — added a `.kiro/` steering context file (gitignored), a
  `cfn-lint` pre-commit hook under `.githooks/`, this `BACKLOG.md`, and `CHANGELOG.md`. Removed a
  redundant `DependsOn: IPAddress` in the (now-removed) OpenVPN template to get a clean lint.

## Decisions on record

Settled tradeoffs — do NOT "fix" these without asking.

- **Multi-region by design.** Three regions (LHR/CMH/GRU) with identical WireGuard config and
  shared peer keys, so one client config works against any of them — the point is choosing an
  exit location. Don't collapse to a single region.
- **Compile `wireguard-tools` from source** in the template (AL2023 packaging history). Not a bug.
- **AMI comes from SSM** (`al2023-ami-kernel-default-arm64`), not a static AMI map — so it never
  rots.
