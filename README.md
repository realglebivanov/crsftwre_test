# CrsftwreTest

Phoenix API app that sorts shell tasks by their dependencies. It serves `POST /tasks/format`.

## Local

```bash
asdf install
mix setup
mix phx.server
```

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

Use `Accept: text/plain` to get a bash script instead of JSON.
