# Governance validation tests

This directory defines **validation tests for the governance architecture** itself. They ensure that skills, checklists, and agents stay consistent and do not break silently.

## Purpose

- **Skills**: Every skill must reference only existing checklists; referenced paths must resolve.
- **Checklists**: Every checklist must have required structure (`id`, `domain`, non-empty `steps` or `steps_contract`).
- **Agents**: Every agent must reference only existing skills under `skills/`.

Results are **pass** or **fail**. A missing reference or invalid structure produces **fail**.

## Layout

- `tests/governance/skills/` — validations for skill files (e.g. `skill-references.yml`).
- `tests/governance/checklists/` — validations for checklist files (e.g. `checklist-structure.yml`).
- `tests/governance/agents/` — validations for agent files (e.g. `agent-skill-references.yml`).

The YAML files in these directories describe the validation rules. The actual checks are run by:

```bash
./scripts/validate-governance.sh
```

Exit code 0 = pass, 1 = fail.

## Integration with CLI

These tests are discoverable and runnable by a governance CLI. When you use:

```bash
iagt-governance validate
```

it should invoke `scripts/validate-governance.sh` (or equivalent) so that the same governance validations run. The stack does not require a specific CLI binary; the script is the canonical runner.

## Backward compatibility

Existing tests under `tests/unit/` (and `tests/integration/`, `tests/fixtures/`, etc.) are unchanged. Governance tests are additive and live only under `tests/governance/`.
