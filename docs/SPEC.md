# Task formatter spec

## Intent

A client sends a list of shell tasks, where a task can require other tasks to run first.
The service returns the tasks in an order where every task comes after everything it requires.
The result is either JSON or a bash script that can be run as-is.

The service only reorders commands. It never executes them.

## Interface

`POST /tasks/format` with a JSON body that matches [`priv/schemas/tasks.json`](../priv/schemas/tasks.json).

```json
{
  "tasks": [
    {"name": "task-1", "command": "touch /tmp/file1"},
    {"name": "task-2", "command": "cat /tmp/file1", "requires": ["task-1"]}
  ]
}
```

| Field | Rule |
| --- | --- |
| `tasks` | Required array |
| `name` | Required, non-empty string |
| `command` | Required, non-empty string |
| `requires` | Optional array of unique, non-empty strings |

Unknown fields are rejected.

The `Accept` header picks the response format:

| `Accept` | Response |
| --- | --- |
| `application/json`, `*/*` or none | `{"tasks": [{"name": ..., "command": ...}]}` |
| `text/plain` | `#!/usr/bin/env bash` followed by one command per line |

## Ordering rules

1. Every task appears after all the tasks it requires.
2. Among tasks that become ready at the same time, input order is kept. The output is deterministic and stays close to what the client wrote.
3. Sorting is linear in the number of tasks plus requirements, using Kahn's algorithm.

## Errors

| Problem | Status | Body |
| --- | --- | --- |
| The body is not valid JSON | 400 | `{"errors": ["Bad Request"]}` |
| The `Accept` header asks for an unsupported format | 406 | `{"errors": ["Not Acceptable"]}` |
| The payload breaks the schema | 422 | `{"errors": [{"path": "#/tasks/0", "message": "..."}]}` with every violation listed |
| A task can't be scheduled | 422 | `{"errors": ["Couldn't resolve N deps for task NAME"]}` |

A task can't be scheduled when it requires an unknown task, requires itself, sits in a cycle, or depends on another task that can't be scheduled.
`N` is the number of its requirements still unresolved.
Tasks that were scheduled before the failure are not reported.

## Acceptance criteria

Each criterion is covered by a test in `test/`.

- The example `task-1`, `task-2 requires task-3`, `task-3 requires task-1`, `task-4 requires task-2 and task-3` comes back as `task-1`, `task-3`, `task-2`, `task-4`, in both formats.
- An empty task list returns `{"tasks": []}`, or only the shebang line as text.
- Tasks with no requirements keep their input order.
- Tasks unblocked by the same requirement keep their input order.
- A task without `command` returns 422 with path `#/tasks/0`.
- A two-task cycle returns 422 naming both tasks.
- An unknown requirement returns 422 naming the task that needs it.
- `Accept: */*` returns JSON.
- Malformed JSON returns 400.
- `Accept: application/xml` returns 406.

## Known gaps

- **Duplicate task names are accepted.** Every copy is kept in the output, and a task that requires the name runs after all of them.
- **Commands are not validated or escaped.** The text response runs whatever the client sent, so the client owns what the script does.
- **There is no authentication or rate limiting.** The request body limit is the Plug default.
