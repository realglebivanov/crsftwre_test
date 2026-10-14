# CrsftwreTest

Phoenix API app that sorts shell tasks by their dependencies. It serves `POST /tasks/format`.
The behaviour and acceptance criteria are in [docs/SPEC.md](docs/SPEC.md).

## Local

```bash
asdf install
mix setup
mix phx.server
```

## Checks

```bash
mix precommit
```

This runs the compiler with warnings as errors, an unused-deps check, the format check, `credo --strict`, `dialyzer` and the tests.
CI runs the same steps and also builds the Docker image.

## Docker

```bash
docker compose up --build              # web server on localhost:4000
docker compose run --rm --build test   # run tests
```

## Example

```bash
curl -X POST http://localhost:4000/tasks/format \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  --data @- <<'EOF'
{
  "tasks": [
    {"name": "task-1", "command": "touch /tmp/file1"},
    {"name": "task-2", "command": "cat /tmp/file1", "requires": ["task-3"]},
    {"name": "task-3", "command": "echo 'Hello World!' > /tmp/file1", "requires": ["task-1"]},
    {"name": "task-4", "command": "rm /tmp/file1", "requires": ["task-2", "task-3"]}
  ]
}
EOF
```

```bash
curl -s -X POST http://localhost:4000/tasks/format \
  -H 'Content-Type: application/json' \
  -H 'Accept: text/plain' \
  --data @- <<'EOF' | bash
{
  "tasks": [
    {"name": "task-1", "command": "touch /tmp/file1"},
    {"name": "task-2", "command": "cat /tmp/file1", "requires": ["task-3"]},
    {"name": "task-3", "command": "echo 'Hello World!' > /tmp/file1", "requires": ["task-1"]},
    {"name": "task-4", "command": "rm /tmp/file1", "requires": ["task-2", "task-3"]}
  ]
}
EOF
```

## How I used AI

I used Claude Code for the project tooling and docs: the Docker setup, the Credo and Dialyzer configuration, the CI workflow, and this README.
I reviewed each change and corrected it when it drifted.
The rules in [AGENTS.md](AGENTS.md) come from those corrections, and each one says what prompted it.

The core logic in `CrsftwreTest.Commands.Sorter` and `CrsftwreTestWeb.Controllers.TaskController` was written by hand using Kahn's algorithm. It wouldn't make much sense to generate it with AI considering the assinment was mostly about implementing the algorithm. 

`mix precommit` is the feedback loop, and it caught mistakes that looked fine in review.
Dialyzer rejected a spec that said the text view returns `iodata()`, although it always returns a list.
Strict Credo flagged the sort function as too complex, which led to splitting it into two helpers.
