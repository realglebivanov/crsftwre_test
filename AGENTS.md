Phoenix JSON API with one endpoint, `POST /tasks/format`, that sorts shell tasks by their dependencies.
The behaviour, error contract and acceptance criteria are in [docs/SPEC.md](docs/SPEC.md).

## Layout

- `lib/crsftwre_test/commands/parser.ex` validates the payload against `priv/schemas/tasks.json` and builds `Command` structs.
- `lib/crsftwre_test/commands/sorter.ex` orders commands with Kahn's algorithm.
- `lib/crsftwre_test_web/controllers/` holds the controller, the fallback controller, and the JSON and TEXT views.

## Commands

- `mix precommit` runs every check: compile with warnings as errors, unused deps, format, `credo --strict`, `dialyzer`, tests. Run it when you are done and fix everything it reports.
- `docker compose run --rm --build test` runs the tests in Docker.
- CI in `.github/workflows/ci.yml` runs the same checks and builds the Docker image.

## Boundaries

- **You may change** code and tests under `lib/` and `test/`, and the Docker, CI and README files.
- **Ask first** before adding a dependency, or changing the JSON schema, the response shapes or the error messages. Clients depend on them, and the tests pin them.
- **Never** edit `mix.lock`, `_build/`, `deps/` or `priv/plts/` by hand. Mix generates them.
- **Never** loosen `.credo.exs`, the Dialyzer flags or the precommit steps to get a check passing. Fix the code instead.

## Rules added while working

- **Do not add code comments.** Added after the agent annotated new helpers and the Credo config with explanatory comments. Names, specs and tests carry the meaning here, and comments drift.
- **Use `@moduledoc false` instead of inventing docs.** Added after the agent wrote module docs only to satisfy Credo. A doc written to please a linter adds noise, not information.
- **Checks must fail, not fix.** Precommit runs `mix format --check-formatted`. Added after the agent wired plain `mix format` into precommit. A check that rewrites files hides the problem and behaves differently from CI.
- **Specs must match what the function returns.** Added after Dialyzer rejected a spec that said the text view returns `iodata()` when it always returns a list.
- **Check documentation against the code.** Added after the agent wrote in the README that routes live under `/api`, which they don't.
- **Keep tooling proportional to the project.** Added after the agent built a hook-based harness for a one-endpoint API. One command and CI are enough.
- **Keep input order among tasks that are ready at the same time.** The output must be deterministic and close to what the client wrote, and the sorter tests pin it.

## Elixir rules

- Lists do not support index access with `list[i]`. Use `Enum.at/2` or pattern matching.
- Bind the result of `if`, `case` and `cond` to a variable. Rebinding inside the block has no effect outside it.
- One module per file.
- Structs don't implement Access, so use `struct.field`, never `struct[:field]`.
- Never call `String.to_atom/1` on user input.
- Predicate functions end in `?` and don't start with `is_`. Reserve `is_` for guards.
- In tests, start processes with `start_supervised!/1`. Don't use `Process.sleep/1`. Wait with `Process.monitor/1` and `assert_receive`, or call `:sys.get_state/1`.
- Read `mix help <task>` before using an unfamiliar Mix task.
- Phoenix router scopes prefix their alias onto module names. Don't repeat the prefix in routes.
