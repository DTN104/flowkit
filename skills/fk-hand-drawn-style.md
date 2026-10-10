# fk-hand-drawn-style — Hand-Drawn Style Pack (18 image materials)

18 hand-drawn / illustration styles packaged as Flow Kit **custom materials** (`hd_*`), ported from
[threerocks/hand-drawn-styles](https://github.com/threerocks/hand-drawn-styles) (MIT). Once registered they
work exactly like the built-in materials: set `material: "hd_<style>"` at project creation and every entity
reference image and scene image inherits the look. Videos are then generated image-to-video from those frames.

Source of truth for the recipes: `skills/hand-drawn-styles/materials.json` (+ upstream originals in
`skills/hand-drawn-styles/upstream/`). Read `skills/hand-drawn-styles/README.md` for what was changed in the port.

---

## 1. One-time setup — register the materials

```bash
scripts/fk_hand_drawn_materials.sh            # adds every hd_* material (skips ones already present)
scripts/fk_hand_drawn_materials.sh --list     # verify
```

Materials persist in `flow_agent.db` and reload on agent start. Re-run with `--force` after editing
`materials.json`. Requires the agent running (`./run.sh`) and `jq`.

Check from the API: `curl -s http://127.0.0.1:8100/api/materials | jq -r '.[] | select(.id|startswith("hd_")) | .id'`

---

## 2. Pick a style

If the user names a style (id, number, alias, or a description like "like a kid drew it"), use it.
If the user only says "hand-drawn" / "doodle" / "sketch", **show this menu and wait** — several styles
share those words (`doodle` alone could be #4, #5 or #6).

| Material id | # | Look (one line) | Best for | Video motion hint |
|---|---|---|---|---|
| `hd_xkcd` | 1 | Thin black stick figures on cream paper, zero fills/shading | explainer, tech humor | limited 2D, static camera |
| `hd_kid_crayon` | 2 | 5-year-old's deliberately bad crayon drawing | comedy, kids' POV, "drawn by a child" | limited 2D, wobble ok |
| `hd_ghibli` | 3 | Ghibli watercolor, ONE focal subject, uncluttered | warm stories, nature, slice of life | slow pan / gentle push-in |
| `hd_bean_doodle` | 4 | Solid-black blob people, outline objects, one orange accent | explainer, process, how-it-works | limited 2D, static |
| `hd_ms_paint` | 5 | Mouse-drawn MS Paint "the worse the better" | memes, absurd comedy | jerky limited 2D |
| `hd_ballpoint_scribble` | 6 | Black ballpoint tangled-line sketch | portraits, animals, moody intros | very subtle, mostly still |
| `hd_crayon_photo` | 7 | Phone PHOTO of a real crayon page, sparse waxy coloring | authentic kid-art feel, cards | paper stays still, tiny motion |
| `hd_ink_wash` | 8 | Chinese ink wash, five ink tones, vast blank paper, red seal | poetry, calm, nature, history | slow drift, ink-bloom reveals |
| `hd_pixel_art` | 9 | 8/16-bit sprite, hard pixels, dithering | retro games, tech, nostalgia | step-wise / low-fps feel |
| `hd_emo_sketch` | 10 | Indigo pen sketch, 60-70% white, ONE orange item | tear-jerker family stories | minimal, hold frames |
| `hd_retro_concept` | 11 | 1950s Disney/UPA gouache concept, high-key white paper | retro character pieces | gentle, 2D only |
| `hd_sunlit_storybook` | 12 | Pixar vis-dev gouache, huge flat irises, teal x orange | storybook characters, i2v anchors | gentle, warm light drift |
| `hd_paper_folk` | 13 | Layered paper-craft diorama, Nordic folk motifs, real shadows | craft/editorial, folk tales | slight parallax between layers ok |
| `hd_nordic_storybook` | 14 | Scandinavian gouache picture book, denim x mustard, grainy paper | quiet picture-book stories | minimal 2D |
| `hd_softnose_vinyl` | 15 | Matte vinyl art-toy render, giant drooping nose, no eyebrows | character series, street vibe | soft 3D turntable ok |
| `hd_gouache_spotlight` | 16 | Full-bleed muted amber field, spotlight glow, painterly | character portraits, i2v anchors | gentle, 2D |
| `hd_inked_storybook` | 17 | Sketchy ink lines over clean digital color, sketchbook margin | expressive character pages | minimal, margin stays fixed |
| `hd_warm_flat_storybook` | 18 | Flat geometric silhouettes, no outlines, navy x coral | modern picture books, family | clean limited 2D |

Upstream aliases still work for recognition: `xkcd` `stickman` (1) / `crayon` (2) / `ghibli` (3) / `bean` `blob` (4) /
`ms-paint` `ugly` (5) / `scribble` `ballpoint` (6) / `real-crayon` (7) / `ink-wash` `shuimo` (8) / `pixel` `8-bit` (9) /
`emo-sketch` `light-watercolor` (10) / `retro-concept` `mid-century` (11) / `sunlit-storybook` `vis-dev` (12) /
`paper-folk` `papercraft` (13) / `nordic-storybook` `scandi-gouache` (14) / `softnose` `vinyl-toy` (15) /
`gouache-spotlight` (16) / `inked-storybook` (17) / `warm-flat-storybook` (18).

**Not in the pack:** upstream 3.1 (family crayon card), 19 (roundhead-redline) and 20 (warm-yellow-ink-story) require a
style-anchor PNG passed with every request plus a staged correction / validator workflow on a locked model snapshot.
Flow Kit generates through Google Flow and cannot honor that contract, so they were left out rather than ported badly.

---

## 3. Use it in a project

```bash
curl -X POST http://127.0.0.1:8100/api/projects -H "Content-Type: application/json" -d '{
  "name": "Bữa cơm chiều",
  "story": "...",
  "material": "hd_emo_sketch",
  "characters": [
    {"name": "Mẹ", "entity_type": "character",
     "description": "Vietnamese woman in her 50s, hair in a low bun, thin frame, wearing a plain áo bà ba and an ORANGE knitted scarf"},
    {"name": "Căn bếp", "entity_type": "location",
     "description": "Small Vietnamese kitchen, round wooden table, rice cooker, one window"}
  ]
}'
```

Then the normal pipeline: `/fk-gen-refs` → `/fk-gen-images` → `/fk-gen-videos` → `/fk-concat`.

### Rules carried over from the upstream protocol (adapted to Flow Kit)

1. **Style lives in the material only.** Entity `description` = appearance only; scene `prompt` = action +
   environment only. Do not add "watercolor", "sketch", "crayon" etc. yourself — `style_instruction` /
   `scene_prefix` already inject it, and a second style block makes the model average two recipes.
2. **No text in images.** Every `hd_*` material ends with "No text anywhere". Titles, captions and labels go
   through `/fk-gen-text-overlays` after the video exists, not into prompts.
3. **No aspect-ratio words in prompts.** Flow Kit decides orientation at project level; the recipes were
   stripped of ratio and multi-panel layout hints on purpose.
4. **One material per project.** Do not switch `material` mid-project: `scene_prefix` is baked into each
   scene's `prompt` at creation and refs are already rendered. To change style, start a new project
   (or delete and re-create scenes).
5. **Consistency still comes from refs.** For the deliberately crude styles (#2, #5, #7) expect more drift
   between scenes than with `3d_pixar`; keep entity descriptions short and distinctive (one signature
   garment, one hair shape) so the ref image carries the identity.

### Style-specific notes

- `hd_emo_sketch` (#10) — the recipe allows exactly **one** orange item in the whole picture. Choose it once per
  project (scarf, backpack, umbrella, dress...), spell it out as "ORANGE <item>" in **one** entity's
  description, and never mention orange anywhere else. Keep that entity in `character_names` of every scene
  that should carry the accent.
- `hd_bean_doodle` (#4) — same idea per scene: name the single key object in the scene prompt
  ("the orange accent is the coffee cup").
- `hd_gouache_spotlight` (#16) — background is fixed to muted amber-orange, which suits blue/teal subjects. For a
  warm-orange subject, copy the entry in `materials.json` as `hd_gouache_spotlight_blue`, change
  "warm amber-orange" to "soft sky-blue" in `style_instruction` and `scene_prefix`, re-run the script.
- `hd_sunlit_storybook` (#12) — entity refs use the "raw white paper border" variant; scene images use the
  upstream "full-bleed high-key" variant via `scene_prefix`. That is intentional (refs = character sheets,
  scenes = environments).
- `hd_paper_folk` (#13) and `hd_softnose_vinyl` (#15) are soft-3D renders, not drawings — they tolerate camera
  moves with depth better than the rest of the pack.
- `hd_crayon_photo` (#7) — the whole frame is "a photo of paper"; keep scene prompts simple (one action, one
  place) or the model fills the paper with clutter.

---

## 4. Writing `video_prompt` for hand-drawn materials

Videos start from the scene image (i2v), so the style mostly carries over — the usual failure is the video model
drifting toward 3D / photoreal once things move or the camera travels in depth. `/fk-camera-guide` still applies
for structure (camera as its own sentence, `Audio:` at the end, `Negative:` at the end); adjust the style slot:

- Say the medium every time: `2D hand-drawn animation; the drawing itself moves, the paper and texture stay still.`
- Prefer camera moves that do not reveal depth: `locked-off static`, slow `pan`, slight `push in`. Avoid
  `crane`, `arc shot`, `rack focus`, `POV` for the flat styles (#1, #2, #4-#11, #14, #17, #18).
- Limited animation reads more "drawn": fewer, held poses; hand-flicker is fine for #1/#2/#5/#7.
- Mirror the material's negatives: `Negative: 3D render, CGI, photorealistic, smooth gradients, subtitles, watermark, text overlay.`
  (add `NOT anti-aliased` for #9, `NOT glossy` for #15, etc.)
- For #7 and #17 the paper / sketchbook margin is part of the style — tell the model it stays fixed.

Example (hd_emo_sketch, 8s):

```
0-3s: Locked-off static shot. Mẹ sets a bowl of rice on the table in Căn bếp, slow careful movement, 2D hand-drawn
animation, the indigo sketch lines flicker slightly, the white paper stays still. Silence, faint clink of the bowl.
3-6s: The camera pushes in very slightly. She looks at the empty chair, shoulders drop. Audio: soft kitchen ambience.
6-8s: Hold on her face, a short jittery line beside her suggests a sigh. Negative: 3D render, photorealistic,
full-color painting, subtitles, watermark, text overlay.
```

These motion rules are Flow Kit guidance, not upstream-verified — upstream only ever produced still images.
Draft at 480p first, keep what holds the style, then re-run at 720p (same as the normal workflow).

---

## 5. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `POST /api/materials` → 400 "Cannot override built-in" | id clash | ids in this pack are all `hd_*`; check you didn't rename one to `ghibli`/`watercolor` |
| → 429 "Custom material limit reached (50)" | too many custom materials | `scripts/fk_hand_drawn_materials.sh --remove` or delete unused ones |
| Refs look right, scenes lose the style | scene created before material was set, or prompt carries a competing style | check scene `prompt` starts with the `scene_prefix`; recreate the scene |
| Video goes 3D / photoreal | camera move with depth, or no medium stated | section 4 |
| Text / captions appear in images | prompt mentions title, sign, label | remove; use `/fk-gen-text-overlays` |
| Style unknown after agent restart | DB reset / different `flow_agent.db` | re-run the script |
