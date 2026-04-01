# AGENTS.md — PrestaShop Project

Instructions for AI coding agents working in this project.
Stack: PrestaShop 8.x Legacy (governance {{STACK_VERSION}})

---

## Architecture constraints

This is a PrestaShop 8.x **legacy** project. These constraints are non-negotiable:

- **No namespaces** — all classes in global namespace
- **No Composer autoload** — use `require_once _PS_MODULE_DIR_ . '...'`
- **No Symfony DI** — use static methods or direct instantiation
- **Service Layer mandatory** — business logic ONLY in `classes/Iagt*Service.php`
- **`Iagt` prefix on all custom classes** — `class IagtOrderService {}`, never `class OrderService {}`
- **Multishop always** — every query must filter by `id_shop`
- **Overrides prohibited** — use hooks; overrides require a documented exception in `exceptions.md`

If unsure about architecture, read `.cursor/rules/governance-stack.mdc` before writing code.

---

## Safety — always ask before

- `git push`, `git commit`, or any destructive git operation
- Modifying core PrestaShop files (`classes/`, `controllers/`, `override/`)
- Running `composer install` or modifying `composer.json`
- Executing SQL directly on any environment
- Deleting files or directories
- Modifying `.env`, `parameters.php`, or any secrets file
- Note: `parameters.php` and `.env` files are automatically redacted before their contents reach the LLM
- Installing or uninstalling modules on any environment

Allowed without asking:
- Reading and searching files
- Creating or editing files in `modules/vendor_*/`
- Running `iagt-governance validate`
- Running `/review` or any governance command

---

## Governance commands

Run these before creating a PR. They are slash commands in Cursor chat.

```
/review               → always, without exception
/security-check       → if you touched SQL, inputs, uploads, or external APIs
/multishop-check      → if you touched queries with persistent data
/servicelayer-review  → if you added or changed business logic
/api-hardening        → if you touched external API integrations
/high-concurrency-check → if you touched stock, checkout, or cron jobs
```

A 🔴 result **blocks the PR**. Do not proceed with unresolved 🔴 findings.
Paste the `/review` output in the PR description.

---

## Module structure

All modules live in `modules/vendor_<name>/`. Structure:

```
modules/vendor_name/
├── vendor_name.php          ← main class (Iagt_Name extends Module)
├── index.php              ← required in EVERY directory
├── classes/
│   ├── index.php
│   └── IagtNameService.php  ← business logic here
├── controllers/admin/
├── controllers/front/
├── sql/
│   ├── install.sql
│   └── uninstall.sql
└── views/templates/
```

Never put business logic in hooks or controllers — delegate immediately to Service.

---

## Plan Mode

For features touching multiple layers (Service + Controller + DB + hook):

1. Press `Shift+Tab` to activate Plan Mode
2. Verify the plan routes logic to Service Layer
3. Verify multishop handling is explicit
4. Approve only if architecture constraints are respected

---

## PR instructions

- **Title**: `[vendor_<module>] <short description>`
- Run `/review` and paste output in the PR description
- All 🔴 findings resolved before requesting review
- Exceptions require documentation in `exceptions.md`

---

## Recommended models

Use the right model for each type of task:

| Task | Recommended model | Why |
|------|-------------------|-----|
| Daily implementation | Composer 2 Fast | Optimized for Cursor multi-file editing |
| Codebase exploration | Composer 2 Fast | Semantic navigation, pattern detection |
| Architecture proposal (`/sdd:new`) | claude-sonnet-4-6 | Better reasoning for design decisions |
| Technical specification (`/sdd:continue`) | claude-sonnet-4-6 | Precise contracts, fewer hallucinations |
| Verification before PR (`/sdd:verify`) | claude-sonnet-4-6 | Critical analysis against spec |
| Subagent auditors (security, multishop) | Composer 2 Fast | Read-only pattern matching, low cost |
| Complex or critical features | claude-opus-4-6 | Maximum reasoning for high-risk changes |

**Rule:** Composer 2 Fast to execute. Claude Sonnet to decide.

To switch model: click the model selector in Cursor's chat bar before starting the task.


---

## Verification

```bash
iagt-governance doctor    # verify governance setup
iagt-governance validate  # run governance tests
```
