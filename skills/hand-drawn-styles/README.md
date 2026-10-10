# hand-drawn-styles — style pack for Flow Kit

Port of [threerocks/hand-drawn-styles](https://github.com/threerocks/hand-drawn-styles) into Flow Kit's
material system. Local addition, not part of upstream Flow Kit.

| File | What |
|---|---|
| `materials.json` | 18 Flow Kit custom materials (`hd_*`) — the thing the agent actually uses |
| `../fk-hand-drawn-style.md` | the skill: menu, how to use, video-prompt rules |
| `../../scripts/fk_hand_drawn_materials.sh` | registers `materials.json` via `POST /api/materials` |
| `upstream/STYLES.md` | original recipes (Chinese + English), kept verbatim for reference |
| `upstream/PROTOCOL.md` | original agent protocol (style selection, placeholders, ratio rules) |
| `upstream/README.md`, `upstream/LICENSE` | upstream docs + MIT license |

Upstream snapshot: commit `cdfd004` (2026-10-08). Example images were **not** vendored (~100 MB); see them on GitHub.

## Mapping

| Upstream | Flow Kit material | Template language | Changes in the port |
|---|---|---|---|
| 1 极简黑白线条讲解漫画 (xkcd) | `hd_xkcd` | zh → en (translated) | multi-panel grid + Chinese captions dropped; single-frame style only |
| 2 蜡笔童涂 | `hd_kid_crayon` | en (verbatim) | title placeholder → "No text" |
| 3 吉卜力风 | `hd_ghibli` | en (verbatim) | — (differs from built-in `ghibli`: anti-clutter / smooth-gradient recipe) |
| 4 小豆人涂鸦信息图 | `hd_bean_doodle` | en (verbatim) | vertical stacked panels + Chinese labels dropped |
| 5 MS Paint 烂涂鸦 | `hd_ms_paint` | zh → en | — |
| 6 圆珠笔单线涂鸦 | `hd_ballpoint_scribble` | zh → en | — |
| 7 蜡笔实拍 | `hd_crayon_photo` | en (verbatim) | title placeholder → "No text" |
| 8 水墨写意 | `hd_ink_wash` | zh → en | — |
| 9 复古像素 | `hd_pixel_art` | zh → en | — |
| 10 情绪叙事淡彩速写 | `hd_emo_sketch` | zh → en | `【橙色关键物】` → "ONE key item, chosen per project" (see skill); side-text dropped |
| 11 二维水彩风格 | `hd_retro_concept` | zh → en | `【背景浓度】` fixed to default; `【焦点物件】` = none; compressed to 2000 chars |
| 12 暖光童画 | `hd_sunlit_storybook` | en (verbatim) | entity refs = "paper border" variant, `scene_prefix` = "full-bleed high-key" variant |
| 13 北欧纸雕 | `hd_paper_folk` | en (verbatim) | defaults: ochre-brown backdrop, default folk pieces |
| 14 北欧绘本水粉 | `hd_nordic_storybook` | en (verbatim) | defaults: warm off-white paper, full-body shadow variant |
| 15 大鼻软偶 | `hd_softnose_vinyl` | en (verbatim) | defaults: sleepy eyes, blush-pink skin, blush-peach backdrop; stubble made conditional in text; "square composition" dropped |
| 16 聚光水粉立绘 | `hd_gouache_spotlight` | en (verbatim) | background fixed to amber-orange (blue variant = copy the entry) |
| 17 墨线绘本 | `hd_inked_storybook` | en (condensed) | palette placeholder → "restrained 2-4 colors"; compressed to 2000 chars |
| 18 暖色扁平绘本 | `hd_warm_flat_storybook` | en (condensed) | compressed to 2000 chars |
| 3.1 蜡笔童涂-潦草自画版 | — | — | **not ported**: needs `assets/style-3.1/anchor-family.png` with every request + 3-stage correction workflow |
| 19 圆头红线极简童画 | — | — | **not ported**: needs anchor PNG + locked `gpt-image` snapshot + acceptance contract |
| 20 暖黄墨线情绪小剧场 | — | — | **not ported**: needs anchor PNG + `validate_style_20_asset.py` |
| Appendix A 实拍纸质感增强层 | — | — | not a material; paste into `style_instruction` of #2 if the "photo of paper" feel is wanted (#7 already has it) |

## Why these changes

Flow Kit's material = `style_instruction` (appended to every entity ref prompt) + `scene_prefix` (prepended to
every scene prompt) + `negative_prompt` + `lighting`. Upstream recipes are one-shot prompts with a
`【主体】` slot and sometimes a layout. So:

- **Subject/title/text placeholders removed** — Flow Kit supplies the subject from entity descriptions and
  scene prompts; text belongs to `/fk-gen-text-overlays`.
- **Ratio / layout removed** — upstream itself says "never hard-lock the ratio"; Flow Kit sets orientation per
  project. Layout styles (#1, #4) become single-frame looks.
- **English everywhere** — Flow Kit prompts and `COMPOSITION_GUIDELINES` are English; mixing languages inside one
  prompt is a known way to lose the style. Translated entries are marked above and are **not upstream-verified**
  (upstream validated on gpt-image / Midjourney, Flow Kit renders through Google Flow — expect to tune).
- **`lighting` overridden** — Flow Kit's default "Studio lighting, highly detailed" would wreck flat styles.
- **API limits** — `style_instruction` ≤ 2000, `scene_prefix` ≤ 500, `negative_prompt` ≤ 1000, `lighting` ≤ 200
  chars; three long recipes were condensed to fit.

## Updating from upstream

```bash
git clone --filter=blob:none --no-checkout --depth 1 https://github.com/threerocks/hand-drawn-styles.git /tmp/hds
cd /tmp/hds && git sparse-checkout set --no-cone '/*.md' '/LICENSE' && git checkout
cp /tmp/hds/{STYLES.md,PROTOCOL.md,README.md,LICENSE} <flowkit>/skills/hand-drawn-styles/upstream/
```

Then diff `upstream/STYLES.md`, carry changes into `materials.json`, re-run
`scripts/fk_hand_drawn_materials.sh --force`.
