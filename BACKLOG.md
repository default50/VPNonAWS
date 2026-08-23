# Backlog

How this file works:

- **Active backlog** — work committed to doing. Tracked with `- [ ]` checkboxes.
- **Done** — shipped work, one line each. Full detail lives in `CHANGELOG.md` and git history;
  this section is just an index of what's settled.
- **Decisions on record** — settled tradeoffs worth not re-litigating.

## Active backlog

### Cleanup

- [ ] **Retire OpenVPN entirely.** OpenVPN is no longer used and won't be again. Remove the
      OpenVPN path once and for all: delete `openvpn-aws.template.yaml` and `OpenVPN-AMIs.sh`,
      drop the OpenVPN mentions from `README.md`, and delete the stale `openvpn_improvements`
      branch (local + remote). Check the account first for any lingering OpenVPN CloudFormation
      stacks / EC2 / EIPs and tear them down (confirm-first, they may already be gone).

### Hardening

- [ ] **Lock down SSH ingress.** The WireGuard security group opens TCP 22 to `0.0.0.0/0`.
      Safe to tighten: the tunnel is UDP 51280, so port 22 is admin-only and restricting it does
      not affect VPN connectivity. Either add a `SSHAllowedCIDR` parameter (default to something
      tight, update when your IP changes), or drop inbound SSH entirely and rely on SSM Session
      Manager for admin access (no inbound port — needs the SSM agent + an instance IAM role).

### Low priority

- [ ] **cfn-guard policy checks.** Layer `cfn-guard` on the existing `cfn-lint` pre-commit hook to
      enforce project rules (no unintended `0.0.0.0/0` ingress, IMDSv2 stays required). `cfn-lint`
      already covers validity, so this is additive — needs the binary plus rule files.

### Tooling

- [ ] **Purpose-built CLI to replace `deploy.sh`.** A small Python CLI (boto3) that supersedes
      the bash script: profile/region resolution (`--flag` > env > committed defaults),
      change-set-based deploys with replacement flagging, a read-only status command (caller
      identity + per-region stack/instance health), and `--dry-run` / `--yes` for a safe
      preview→apply loop with structured, greppable output. Would also make the multi-region
      iteration and the start/stop of the standby (GRU) instance first-class. Larger effort —
      `deploy.sh` is fine for now; this is a "when it's worth it" item.
- [ ] **Start/stop instances on demand (with optional auto-stop timeout).** Give the CLI a way to
      start or stop the WireGuard instances per region (or all at once) without a full deploy —
      handy for waking the standby (GRU) or parking idle regions to save cost. Bonus: start with a
      lease, e.g. `start --for 3h` (accept minutes/hours/days), so the instance auto-stops when the
      lease expires and nothing is left running by accident. Likely implemented with a tag the
      instance carries (`auto-stop-at=<timestamp>`) plus a scheduled sweeper (EventBridge Scheduler
      → a small Lambda, or an in-CLI `sweep` command run from cron) that stops instances whose lease
      has passed. EIP + DNS survive stop/start, so no address churn.

## Done

Shipped work, newest first. Full detail in `CHANGELOG.md` + git history.

- **Repo modernization** (Unreleased) — added a `.kiro/` steering context file (gitignored), a
  `cfn-lint` pre-commit hook under `.githooks/`, this `BACKLOG.md`, and `CHANGELOG.md`. Removed a
  redundant `DependsOn: IPAddress` in the OpenVPN template to get a clean lint.

## Decisions on record

Settled tradeoffs — do NOT "fix" these without asking.

- **Multi-region by design.** Three regions (LHR/CMH/GRU) with identical WireGuard config and
  shared peer keys, so one client config works against any of them — the point is choosing an
  exit location. Don't collapse to a single region.
- **Compile `wireguard-tools` from source** in the template (AL2023 packaging history). Not a bug.
- **AMI comes from SSM** (`al2023-ami-kernel-default-arm64`), not a static AMI map — so it never
  rots.
