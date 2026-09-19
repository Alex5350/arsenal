# Copilot instructions (arsenal)

GitHub Copilot reads this file in VS Code chats and agent sessions. The universal
entry point for all harnesses is AGENTS.md at the repository root; treat it as the
authority. The essentials, restated:

1. `docs/` is the single source of truth. Start at `docs/README.md`, and read
   `docs/harness/copilot.md` for Copilot-specific wiring.
2. Work the loop defined in `docs/workflows/`: research, plan, execute, verify,
   track, publish. Do not write code before a plan exists in writing.
3. Route by tier per `docs/models/routing.md`: you plan and review as the
   strategist, you hand implementation to the executor tier when the harness
   supports it, and you never skip the test gate in `docs/standards/testing.md`.
4. Mirror every unit of work to the team tracker using `docs/integrations/` and
   `scripts/work-item.sh`. Stamp work-item IDs in commits and PRs.
5. Conventional commits only. No secrets in code, logs, or commands.
