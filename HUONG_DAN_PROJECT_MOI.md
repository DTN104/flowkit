khoan# Flow Kit — Hướng dẫn tạo project video mới

Áp dụng cho repo `~/Work/flowkit` (commit `cd9f156`, 25/09/2026). Mỗi lần làm video mới thì đi từ Bước 0 đến Bước 8. Nếu chỉ quay lại project cũ, xem Bước 9.

## Cần hiểu trước: project được gắn với Flow như thế nào

Mỗi project trong Flow Kit ứng với **một project trên Google Flow**, và ID của project Flow Kit **chính là UUID** của project Flow đó. Mọi request (ảnh, video) của project sẽ tự bắn vào đúng project Flow của nó.

Vì vậy làm project mới thì **không cần sửa `run.sh`**. Biến `FLOW_PROJECT_ID` trong `run.sh` chỉ là giá trị dự phòng cho các lệnh không truyền project. Cứ để nguyên, project cũ vẫn chạy bình thường.

```
Flow project (UUID) ──┬── Nhân vật / bối cảnh / đạo cụ  → ảnh tham chiếu (ref)
                      └── Video (1 hoặc nhiều)
                              └── Scene 1..N → ảnh scene → clip ~8s → ghép
```

---

## Bước 0 — Khởi động (mỗi lần mở máy)

1. Mở **Chrome** và kiểm tra extension **Flow Kit** đang bật. Chrome profile này phải **đang đăng nhập acc Google có gói Flow**. Việc đăng nhập chỉ cần làm một lần vì Chrome nhớ cookie, và credit sẽ trừ vào acc này.
   - Không bắt buộc tự mở tab Flow: khi cần gửi request, extension sẽ tự mở ngầm một tab `flow.google.com`. Dù vậy, vẫn nên mở sẵn tab project để F5 xem kết quả.
   - Nếu lỡ đăng xuất, bị hết phiên, hoặc vừa xóa cookie Google, mọi request sẽ fail cho tới khi bạn đăng nhập lại `flow.google.com`.
2. **Terminal 1**, bật agent:
   ```bash
   caffeinate -i ~/Work/flowkit/run.sh
   ```
   Có `caffeinate -i` thì Mac không ngủ trong lúc gen video lâu. Để cửa sổ này chạy suốt.
3. **Terminal 2**, kiểm tra kết nối:
   ```bash
   curl -s http://127.0.0.1:8100/health
   ```
   Kết quả phải có `"extension_connected": true`. Nếu ra `false` thì F5 tab Flow, chờ 5 giây rồi kiểm tra lại.

---

## Bước 1 — Viết brief (ý tưởng)

Chuẩn bị sẵn brief theo mẫu dưới. Brief càng rõ thì Claude viết kịch bản càng đúng ý.

```text
Tên: <tên project>
Ý tưởng: <2–3 câu cốt truyện, có mở – thắt – kết>
Số scene: <3–5 cho lần đầu; ~8 scene ≈ 1 phút>
Khung hình: VERTICAL (9:16, cho Shorts) | HORIZONTAL (16:9)
Phong cách (material): realistic | 3d_pixar | anime | stop_motion | minecraft | oil_painting
Nhân vật: <tên + ngoại hình + 1 bộ trang phục duy nhất>
Bối cảnh: <nơi chốn chính>
Narrator: không | có (ngôn ngữ: vi/en, giọng: ...)
```

Mẹo:

- **Chỉ dùng nhân vật hư cấu.** Người thật hoặc người nổi tiếng rất dễ bị bộ lọc an toàn của Google chặn.
- **Mỗi nhân vật chỉ mặc một bộ đồ.** Muốn đổi trang phục theo scene thì ghi vào mô tả scene, không ghi vào mô tả nhân vật.
- Hành động nên đơn giản, rõ ràng. Mỗi clip chỉ dài khoảng 8 giây.

---

## Bước 2 — Tạo project trên Google Flow

**Cách A (khuyên dùng, đã chạy ổn trên máy bạn):**

1. Vào `https://flow.google.com/`, bấm **New project** và đặt tên.
2. Copy UUID trên thanh địa chỉ:
   `https://flow.google.com/project/`**`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`** ← phần này
3. Mở tab project mới này để lát nữa xem kết quả.

**Cách B (chưa kiểm chứng trên máy bạn):** bỏ qua bước tạo tay và để Flow Kit tự tạo project Flow. Code hiện tại có hỗ trợ việc này (gọi `POST /api/projects` mà không truyền `flow_project_id`), nhưng README lại ghi là không làm được, nên chưa chắc chạy. Nếu báo lỗi thì quay về Cách A.

---

## Bước 3 — Tạo project trong Claude Code

```bash
cd ~/Work/flowkit && claude
```

Trong Claude Code, dán brief kèm UUID:

```text
/fk-create-project <dán brief ở Bước 1>.
Dùng flow_project_id=<UUID ở Bước 2>.
```

Claude sẽ tự làm lần lượt: tạo project và nhân vật → tạo video → viết từng scene (prompt ảnh, prompt video, lời narrator nếu có) → **đặt project này làm active**. Từ đây các skill sau tự nhắm vào project này, bạn không cần gõ ID nữa.

**Duyệt kỹ trước khi đi tiếp**, vì sửa ở bước này là rẻ nhất:

- Mô tả nhân vật chỉ có một bộ trang phục.
- `prompt` và `video_prompt` viết bằng tiếng Anh, chỉ tả hành động và bối cảnh, không tả lại ngoại hình nhân vật.
- `video_prompt` chia mốc thời gian, ví dụ `0-3s: ... 3-6s: ... 6-8s: ...`.
- Muốn sửa thì nói thẳng với Claude, ví dụ "scene 2 cho mèo đứng sau quầy, góc máy thấp". Claude sẽ PATCH scene đó, không cần tạo lại.

Kiểm tra project đang active:

```bash
curl -s http://127.0.0.1:8100/api/active-project | python3 -m json.tool
```

`project_id` phải trùng với UUID ở Bước 2.

---

## Bước 4 — Ảnh tham chiếu (refs)

```text
/fk-gen-refs
```

Chạy xong thì F5 tab project Flow (tab này không tự refresh). Kiểm tra từng ảnh ref:

- Đúng nhân vật như mô tả, nhìn rõ mặt và dáng.
- Ảnh đơn, không bị chia nhiều ô kiểu lưới.
- Chỉ có một bộ trang phục.

Nếu chưa ưng, bảo Claude: *"sửa mô tả nhân vật X thành …, rồi regenerate ref của X"*. Ref là gốc cho mọi scene phía sau, nên sai ở đây thì cả video bị lệch.

---

## Bước 5 — Ảnh từng scene

```text
/fk-gen-images
```

F5 tab Flow rồi xem từng ảnh. Ảnh scene chính là frame đầu của video, nên góc máy, bố cục và ánh sáng đều được chốt ở bước này. Scene nào chưa ưng thì bảo Claude: *"sửa prompt scene N: …, rồi regenerate ảnh scene N"*. Làm lại ảnh sẽ tự xóa video cũ của scene đó.

---

## Bước 6 — Video từng scene

Chọn **một** trong hai cách:

```text
/fk-gen-videos
```
Mỗi scene thành một clip riêng, ghép lại bằng cú cắt thẳng. Ổn định nhất, nên dùng cho lần đầu.

```text
/fk-gen-chain-videos với model_family=omni_flash
```
Có đoạn chuyển cảnh mượt từ scene này sang scene sau. Tốn credit hơn và dễ lỗi hơn.

Mỗi clip mất khoảng 2–5 phút. Model mặc định là loại "low priority" (0 credit) nên có thể chậm hơn. Có thể kiểm tra chất lượng bằng AI trước khi ghép:

```text
/fk-review-video
```

---

## Bước 7 — Lời bình (tùy chọn)

Chỉ cần khi brief có narrator. `run.sh` đã có sẵn `TTS_PYTHON_BIN` trỏ tới `tts-venv`.

```text
/fk-gen-tts-template        ← làm 1 lần để giọng đồng nhất qua mọi scene
/fk-gen-narrator --language vi
```

---

## Bước 8 — Ghép thành video cuối

| Trường hợp | Lệnh |
|---|---|
| Không narrator | `/fk-concat` |
| Có narrator | `/fk-concat-fit-narrator` (tự cắt từng clip cho khớp độ dài lời đọc) |

File cuối nằm trong `~/Work/flowkit/output/<tên-project>/`.

**Đường tắt:** duyệt xong Bước 3 thì có thể gõ một lệnh để chạy hết Bước 4 → 8:

```text
/fk-pipeline --concat           ← không narrator
/fk-pipeline --tts --concat     ← có narrator
```

Đừng thêm `--upscale`, vì upscale 4K chưa hỗ trợ trên API mới. Lần đầu nên chạy lẻ từng bước để kịp kiểm tra ảnh.

---

## Bước 8b — Upload lên Google Drive (tùy chọn)

Skill này mình tự thêm vào, không có trong repo gốc. Nó dùng **rclone** để đẩy file cuối lên Drive, vào folder `FlowKit/<tên-project>/`.

**Setup một lần duy nhất:**

```bash
brew install rclone
rclone config create gdrive drive scope=drive.file
```

Lệnh thứ hai sẽ mở trình duyệt để bạn đăng nhập Google. Đăng nhập acc nào thì video lên Drive của acc đó, không bắt buộc trùng acc Flow. Với `scope=drive.file`, rclone chỉ thấy những file do chính nó tạo, không đọc được phần còn lại của Drive.

**Mỗi lần upload**, trong Claude Code gõ:

```text
/fk-drive-upload
```

Hoặc chạy tay, không cần Claude:

```bash
~/Work/flowkit/scripts/fk_drive_upload.sh
```

- Skill upload `<tên>_narrator_cut.mp4` và/hoặc `<tên>_final.mp4` của project đang active, rồi in ra link Drive.
- File để **riêng tư**. Muốn có link công khai (ai có link đều xem được) thì thêm `--share`.
- Chạy lại nhiều lần cũng không sao: file không đổi thì được bỏ qua, không sinh bản trùng.
- Gộp chung với pipeline: nói với Claude "chạy `/fk-pipeline --concat` xong thì `/fk-drive-upload`".

Lỗi thường gặp:

| Lỗi | Cách xử lý |
|---|---|
| `rclone not installed` / `remote 'gdrive' not configured` | Chạy 2 lệnh setup ở trên |
| `invalid_grant` / token hết hạn | `rclone config reconnect gdrive:` |
| `no ..._final.mp4` | Chạy `/fk-concat` trước |

---

## Bước 9 — Quay lại project cũ

```text
/fk-switch-project
```

Lệnh này liệt kê các project để bạn chọn. Không cần sửa `run.sh` hay restart agent. Muốn xem project đang ở bước nào thì gõ `/fk-status`.

---

## Xử lý sự cố nhanh

Gặp lỗi bất kỳ thì gõ **`/fk-doctor`** trước. Nó đọc log và gợi ý cách sửa.

| Triệu chứng / lỗi | Nguyên nhân | Cách xử lý |
|---|---|---|
| `extension_connected: false` | Tab Flow chưa nối lại sau khi restart agent | F5 tab Flow, kiểm tra extension còn bật |
| Chạy xong mà không thấy ảnh | Tab Flow không tự refresh, hoặc đang mở nhầm project | F5; kiểm tra UUID trên URL |
| `NO_FLOW_PROJECT` | Project không có UUID Flow | Tạo lại theo Bước 2–3, nhớ truyền `flow_project_id` |
| `UNSAFE_GENERATION` | Prompt bị bộ lọc an toàn chặn | Bỏ người thật, bạo lực; đổi góc máy (từ sau lưng / nghiêng) |
| `UNUSUAL_ACTIVITY` / `reCAPTCHA evaluation failed` | Google nghi là bot | Dừng lại; xóa cookie `google.com` + `labs.google`; đăng nhập lại; không hạ throttle |
| `USER_QUOTA_REACHED` | Hết credit trong ngày | Chờ reset hoặc nâng gói |
| `UNSUPPORTED_ON_BATCH_API` | Tính năng chưa hỗ trợ trên API mới (upscale, Veo r2v, Veo chain) | Dùng `model_family=omni_flash`, hoặc bỏ tính năng đó |
| Request kẹt `PROCESSING` rất lâu | Worker hoặc extension bị treo | `/fk-doctor`; F5 tab Flow |
| Link ảnh/video hết hạn (project làm nhiều ngày) | Signed URL có hạn | `/fk-refresh-urls` trước khi ghép |

---

## Checklist rút gọn

```text
[ ] Chrome mở, extension bật, acc Google (có gói Flow) đang đăng nhập
[ ] caffeinate -i ~/Work/flowkit/run.sh   →  /health: extension_connected true
[ ] Viết brief (Bước 1)
[ ] Tạo project trên Flow, copy UUID (Bước 2)
[ ] claude → /fk-create-project <brief> + flow_project_id=<UUID> → duyệt scene
[ ] /fk-gen-refs      → F5, kiểm tra ref
[ ] /fk-gen-images    → F5, kiểm tra ảnh scene
[ ] /fk-gen-videos
[ ] (tùy chọn) /fk-gen-tts-template + /fk-gen-narrator
[ ] /fk-concat  hoặc  /fk-concat-fit-narrator
[ ] Lấy file trong output/<tên-project>/
[ ] (tùy chọn) /fk-drive-upload   → lấy link Drive
```
