# Transfer

Temporary file transfer helper.

Large files are uploaded as GitHub Release assets. Do not commit generated packages to this repository.

## Create Payload

```powershell
.\scripts\create_direct_release_payload.ps1 `
  -SourceDist "E:\Finetune\QWEN3_ASR\dist" `
  -OutputDir ".\release_payload_direct"
```

## Upload Release Assets

```powershell
.\scripts\upload_release_assets.ps1 `
  -Tag "transfer-20260628" `
  -Title "Temporary transfer 2026-06-28" `
  -PayloadDir ".\release_payload_direct"
```

Delete the release when the transfer is done.
