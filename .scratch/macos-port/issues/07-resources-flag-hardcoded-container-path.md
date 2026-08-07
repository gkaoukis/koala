# --resources flag hardcodes /koala or /benchmarks as the repo root

Status: ready-for-agent
Blocked by: none (found during issue-05 validation sweep)

## Summary

`./main.sh <benchmark> --bare --resources` produces zero data points and fails with `Error: Failed to generate benchmark stats` on any `--bare` run whose repo isn't checked out at exactly `/koala` or `/benchmarks` — which is every `--bare` run outside the project's own Docker image (its `Dockerfile` uses `WORKDIR /koala`; CI's docker run mounts at `/benchmarks`). Confirmed on the macOS Tart VM (repo at `/Users/admin/koala-fork`); the same would hit a `--bare` run on a real Debian/Fedora machine checked out anywhere but those two exact paths. Not macOS-specific.

`./main.sh <benchmark> --bare --time` (the sibling flag) works correctly; this is isolated to `--resources`.

## Root cause

`.tools/dynamic_analysis.py`:

```python
def correct_base(path):
    p = Path(path)
    return p.is_relative_to("/koala") or p.is_relative_to("/benchmarks")

def rebase(path):
    p = Path(path)
    if p.is_relative_to("/koala"):
        return p.relative_to("/koala")
    if p.is_relative_to("/benchmarks"):
        return p.relative_to("/benchmarks")
    raise ValueError(f"{p} is not under /koala or /benchmarks")
```

`correct_base()` gates a filter (`if ... and correct_base(file_path)`) used when reading process logs — outside those two paths it always returns `False`, so every process-log entry is silently dropped rather than erroring loudly. The result is an empty `dynamic_analysis.jsonl`, which downstream reports as "no data to plot."

(An earlier working hypothesis — that `--resources` simply finishes before the sampler's first poll tick — was investigated and is not the actual cause; this hardcoded-path check is.)

## Fix (not yet designed)

`correct_base`/`rebase` need to resolve the repo root dynamically (e.g. via `git rev-parse --show-toplevel`, already used everywhere else in this codebase) instead of a fixed allowlist of two absolute paths. Not attempted this session — flagging as a clean, well-scoped, unstarted fix.

## Acceptance

`./main.sh <benchmark> --bare --resources`, run from a repo checked out at an arbitrary path, produces real data in `dynamic_analysis.jsonl` and a non-empty `benchmark_stats.txt` — matching what already happens inside the Docker image today.
