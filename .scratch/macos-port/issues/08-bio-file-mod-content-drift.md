# bio and file-mod: tool-version drift baked into compressed output bytes

Status: ready-for-agent
Blocked by: none (found during issue-05 validation sweep)

## Summary

`bio` and `file-mod` both fail `--min` validation with clean script exits (every stage returns 0) but a hash/checksum mismatch — on macOS, Debian, and Fedora alike, not a platform-specific regression from this port. Root cause in both cases: the tool that produces the compared file embeds its own version (or version-dependent encoder behavior) into the output bytes, so any version difference between whatever generated the baseline `hashes/` and whatever's running now fails the comparison regardless of whether the actual content is correct.

## bio

`bio/validate.sh` does a raw SHA256 of each `.bam` file. `samtools` embeds an explicit version string into the BAM header via `@PG` lines on every operation that touches the file:

```
@PG ID:samtools.2  VN:1.24  CL:samtools reheader - inputs/bio-min/HG00614_SYNTH_MIN.bam
@PG ID:samtools.3  VN:1.24  CL:samtools view -b outputs/HG00614_SYNTH_MIN_corrected.bam chr1
```

This host's samtools (brew formula) is 1.24. Whatever version generated the baseline hashes is presumably different — any difference changes these header bytes, and therefore the SHA256, even though the actual alignment data could be byte-identical.

## file-mod

`file-mod/validate.sh` `md5sum`s five categories of output: `compress_files`, `encrypt_files`, `img_convert`, `thumbnail_generation`, `to_mp3`. Only the two ImageMagick-driven ones (`img_convert`, `thumbnail_generation` — both use `convert -resize`) fail; `compress_files`/`encrypt_files` (not media-specific) and `to_mp3` all pass. Confirmed via `identify -verbose` that this host's `img_convert` output has no obvious literal version string embedded (unlike `bio`'s `@PG` line) — the difference is JPEG re-encoding not being bit-exact across ImageMagick versions/builds for logically-identical operations. `to_mp3`'s validation happens to sidestep this entirely: it hashes *decoded PCM audio* (`ffmpeg -i ... -f md5 -`) rather than the compressed file's bytes, so it's immune to encoder-version drift by construction — the same technique would fix `img_convert`/`thumbnail_generation` if applied there (decode-then-hash rather than hash-the-compressed-bytes), though that changes what's actually being verified (pixel content vs. exact file identity) and isn't a decision to make unilaterally.

This host's ImageMagick: `7.1.2-29 Q16-HDRI`.

## Not fixed

Both are content-drift issues with more than one legitimate fix path (repin exact tool versions to match whatever generated the baseline; regenerate baselines on a documented reference environment; or, for `file-mod`, switch to content-hashing instead of file-hashing the way `to_mp3` already does) — a real decision, not something to pick unprompted. Diagnosis only; not implemented.

## Acceptance

Not yet defined — depends on which fix direction gets picked.
