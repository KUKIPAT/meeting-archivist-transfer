# AI 회의기록관 Transfer

임시 공개 GitHub Release를 통해 `AI 회의기록관` 설치 파일을 회사 인터넷망 PC로 전달하기 위한 저장소입니다.

이 repo에는 큰 설치 파일을 git commit 하지 않습니다. 큰 파일은 반드시 GitHub Release asset으로만 올립니다.

## 사용 흐름

1. 집 PC에서 설치 산출물을 분할 압축합니다.
2. GitHub Release를 만들고 분할 파일과 `SHA256SUMS.txt`를 업로드합니다.
3. 회사 인터넷망 PC에서 Release asset을 다운로드합니다.
4. 해시를 확인하고 내부망 반입 절차로 넘깁니다.
5. 다운로드가 끝나면 Release를 삭제하거나 repo를 private으로 전환합니다.

## 집 PC에서 패키지 만들기

PowerShell에서 이 repo 폴더로 이동한 뒤:

```powershell
.\scripts\create_transfer_package.ps1 `
  -SourceDist "E:\Finetune\QWEN3_ASR\dist" `
  -OutputDir ".\release_payload" `
  -VolumeSize "1200m"
```

결과물:

```text
release_payload/
  runtime-package.7z.001
  runtime-package.7z.002
  ...
  SHA256SUMS.txt
  INSTALL_KO.txt
```

## GitHub Release에 업로드

```powershell
.\scripts\upload_release_assets.ps1 `
  -Tag "transfer-20260628" `
  -Title "Temporary transfer 2026-06-28" `
  -PayloadDir ".\release_payload"
```

업로드가 끝나면 repo의 Releases 페이지에서 asset 다운로드 링크를 확인합니다.

## 회사 PC에서 받는 파일

Release asset에서 아래 파일을 모두 같은 폴더에 받습니다.

```text
runtime-package.7z.001
runtime-package.7z.002
...
SHA256SUMS.txt
INSTALL_KO.txt
```

`INSTALL_KO.txt`에 해시 확인과 압축 해제 방법이 들어 있습니다.

## 주의

- 회사 자료, 회의 녹음, 개인 토큰, 캐시 파일을 절대 올리지 않습니다.
- 공개 Release는 필요한 시간만 열어둡니다.
- 업로드 파일은 2GiB 미만이어야 하므로 기본 분할 크기는 `1200m`입니다.
- repo 파일로 대용량을 commit/push하지 않습니다.

