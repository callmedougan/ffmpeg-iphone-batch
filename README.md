# ffmpeg-iphone-batch

Windows batch scripts to bulk-convert a folder of videos to iPhone-compatible H.264/AAC, with optional NVENC GPU acceleration and automatic CPU fallback for anything the GPU encoder rejects.

## Which script to use

**`convert_to_iphone_v3.bat`** — this is the one to run. It scans a folder, skips files that are already iPhone-compatible, and encodes the rest via either GPU (NVENC) or CPU (libx264), controlled by a single toggle at the top of the file.

`convert_to_iphone CPU.bat` and `convert_to_iphone GPU.bat` are earlier, split versions kept for reference — `_v3` supersedes both with a single `USE_GPU` switch instead of two separate files.

## Scripts

| Script | Purpose |
|---|---|
| `convert_to_iphone_v3.bat` | Main script. Scans a folder, skips already-compatible files, encodes the rest, logs results |
| `retry_failed_with_cpu.bat` | Reads the log for any `FAILED:` entries and retries just those files via CPU |
| `convert_to_iphone CPU.bat` / `convert_to_iphone GPU.bat` | Legacy split versions — kept for reference only |

## Setup

Open `convert_to_iphone_v3.bat` and edit the config block at the top:

```bat
set "FOLDER=C:\path\to\your\videos"
set "USE_GPU=1"
```

- `FOLDER` — the directory to scan (non-recursive)
- `USE_GPU=1` — encode with `h264_nvenc` (requires an NVIDIA GPU with NVENC support)
- `USE_GPU=0` — encode with `libx264` (CPU only, slower but more forgiving)

Requires `ffmpeg` and `ffprobe` on PATH.

## Usage

1. Run `convert_to_iphone_v3.bat`.
2. Check `converted_files.txt` — successful conversions are logged as `Converted: filename`, already-compatible files are noted as such, and anything that failed is logged as `FAILED: filename`.
3. If anything failed, run `retry_failed_with_cpu.bat`. It reads the log, retries only the `FAILED:` entries through the CPU encoder, and rewrites the log in place with the updated results.

Output files are suffixed by the encoder used — `_GPU_iphone.mov` or `_CPU_iphone.mov` — so you can tell at a glance what produced them.

## Known gotchas

- **`goto` + parenthesized `for` blocks in batch don't mix.** cmd.exe parses the whole `( ... )` block before executing it, so a `goto` jumping to a label inside nested parens throws a context-free `") was unexpected at this time."` The scripts avoid `goto` entirely, using flag variables and nested `if` blocks instead.
- **NVENC enforces the H.264 level spec; libx264 doesn't.** A 4K source encoded with `-level 4.0` will make libx264 print warnings and encode anyway (with a technically-mislabeled level). NVENC hard-fails instead: `InitializeEncoder failed: invalid param (8): Invalid Level.` Same underlying issue, different tolerance — this is exactly the kind of failure `retry_failed_with_cpu.bat` exists to catch and recover from.
- **NVENC quality varies noticeably by GPU generation.** Older (Pascal-era, e.g. GTX 1050) NVENC is visibly lower quality than newer (Turing-era, e.g. RTX 2070) NVENC at the same `-cq` value. GPU encoding wins on speed, not necessarily on quality-per-bit.

## License

See [LICENSE](LICENSE).
