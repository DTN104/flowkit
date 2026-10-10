Upload the project's final video(s) to Google Drive via rclone.

Usage: `/fk-drive-upload [project_id | path/to/file.mp4 ...] [--share]`

- No argument → the active project (falls back to the most recent one).
- Uploads whichever of these exist: `output/<slug>/<slug>_narrator_cut.mp4`, `output/<slug>/<slug>_final.mp4` → Google Drive folder `FlowKit/<slug>/`.
- Files stay **private** by default. Add `--share` **only if the user explicitly asks for a shareable link** — it grants "anyone with the link can view".

> Local addition, not part of upstream Flow Kit. Source of truth: `scripts/fk_drive_upload.sh`.

---

## Prerequisites (one-time, done by the user)

```bash
brew install rclone
rclone config create gdrive drive scope=drive.file
```

The second command opens a browser for Google sign-in. `scope=drive.file` limits rclone to files it created itself — it cannot read the rest of the user's Drive.

**Never run `rclone config` yourself** — it needs the user's browser login. If the remote is missing, tell the user to run the commands above and stop.

---

## Step 1: Run the upload

From the repo root:

```bash
scripts/fk_drive_upload.sh                      # active project
scripts/fk_drive_upload.sh <project_id>         # specific project
scripts/fk_drive_upload.sh path/to/file.mp4     # specific file(s), agent not needed
scripts/fk_drive_upload.sh --share ...          # --share must be the FIRST argument
```

Rules:
- Use the script. Do not re-implement the upload with ad-hoc `rclone` calls or loops — the script resolves the project, picks the files, skips unchanged files on re-run, and prints the Drive link.
- Use a long Bash timeout (up to 10 minutes). A 1-minute 1080p video is usually tens of MB.
- If the user asked for upload as part of a pipeline run, run this only after `/fk-concat` or `/fk-concat-fit-narrator` has produced the final file.

---

## Step 2: Report

Tell the user, in their language, for each uploaded file: file name, size, and the Drive link (`https://drive.google.com/file/d/<id>/view`). If `--share` was used, also give the share link and remind them it is public to anyone holding the link.

---

## Errors

| Exit | Message | Fix |
|------|---------|-----|
| 2 | `rclone not installed` / `remote 'gdrive' not configured` | Ask the user to run the prerequisite commands. Do not attempt them. |
| 3 | `cannot reach Flow Kit agent` / `project not found` | Start `run.sh`, check the project id, or pass the `.mp4` path directly |
| 4 | `no <slug>_final.mp4 or <slug>_narrator_cut.mp4` | Run `/fk-concat` or `/fk-concat-fit-narrator` first |
| other | rclone error such as `invalid_grant` / `token expired` | Token revoked or expired → user runs `rclone config reconnect gdrive:` |

---

## Notes

- Destination root: env `FK_DRIVE_DEST` (default `gdrive:FlowKit`), e.g. `FK_DRIVE_DEST=gdrive:Videos/FlowKit`.
- Re-running is safe: unchanged files are skipped, changed files are replaced — no duplicates.
- With `scope=drive.file`, rclone only sees folders it created. A `FlowKit` folder made by hand in the Drive web UI is invisible to it, so rclone creates its own folder with the same name.
- Upload uses the Google account chosen during `rclone config create`, which may differ from the Flow account.
