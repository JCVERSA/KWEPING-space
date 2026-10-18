# tools/archive

This directory contains archived / orphaned files that are not referenced by any
workflow or script in the repository. They are preserved here for reference but
are not executed during RDP provisioning.

- `claude.vm` — historical POSIX-shell installer for `free-claude-code`
  (Python 3.14.0 / uv). Not invoked from any workflow; retained for reference.
  The live installer URL used by `chill.yml` is pinned by commit SHA via
  `scripts/Invoke-RemoteScript.ps1`.
