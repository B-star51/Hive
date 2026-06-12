# Attack Playbooks (synthetic)

These describe the scenarios encoded in `../sample-ad-logs.json`. Add your own
by appending events to that file - the agents pick them up automatically.

## 1. Privilege escalation chain  (entity: `jdoe`)  -> ESCALATED
A normally low-privilege helpdesk account is taken over and elevated:

| Time  | Event | What it shows | Agent |
|-------|-------|---------------|-------|
| 02:14 | 4728  | `jdoe` added to **Domain Admins** by `svc-automation` (off-hours, service acct) | RoleChange (Critical) |
| 02:15 | 4672  | special privileges assigned to `jdoe` | context |
| 02:16 | 4768  | Kerberos TGT for `jdoe` issued from 10.0.0.14 (WKS-014) | TokenMisuse baseline |
| 02:18 | 4769  | service ticket for `jdoe` requested from 10.0.0.1 (DC01) -> pass-the-ticket | TokenMisuse (High) |
| 02:20 | 4624  | `jdoe` logs on to **DC01** (sensitive host) | LateralMovement (High) |

Three agents fire on one entity -> CorrelationAgent raises a **Critical** incident
-> ResponseAgent recommends containment.

## 2. Credential spray  (entity: `guest`)  -> watch only
`guest` fails logon on DC01, SQL01, FILESRV01 within seconds -> LateralMovement
LM-002 (Medium). Only one agent fires, so it stays below the escalation threshold -
demonstrating that correlation, not a single rule, drives escalation.

## 3. Benign noise (should NOT escalate)
- `bsmith` added to **Marketing** (non-privileged group) -> no signal.
- `jdoe` / `arossi` normal daytime workstation logons -> no signal.
