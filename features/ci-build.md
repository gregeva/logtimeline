# Cross-Platform CI/CD Build Feature

## Overview

GitHub Actions CI/CD pipeline for automated cross-platform binary builds of LogTimeLine (ltl).

## Status

**Implementation Complete** - v0.8.2

## Requirements

### Functional Requirements

1. **Automated builds on release tags** - Trigger builds when version tags (e.g., `v0.8.2`) are pushed
2. **Manual trigger support** - `workflow_dispatch` for testing builds without creating tags
3. **Cross-platform support** - Build binaries for macOS, Ubuntu/Linux, and Windows
4. **Multi-architecture support** - ARM64 and amd64 for Ubuntu
5. **Release artifact attachment** - Automatically attach all binaries to GitHub Releases
6. **Build verification** - Verify executables run and report correct version

### Technical Requirements

1. **GitHub Actions workflow** in `.github/workflows/release-build.yml`
2. **macOS runner**: `macos-latest` for ARM64 (Apple Silicon)
3. **Ubuntu runners** with Docker for Linux builds
4. **QEMU emulation** for ARM64 Linux builds
5. **Docker + Wine** for Windows builds
6. **Perl setup** using `shogo82148/actions-setup-perl` action (macOS)
7. **PAR::Packer** for creating standalone executables
8. **Artifact naming** consistent with existing convention

## Output Binaries (4 total)

| Platform | Binary Name | Architecture |
|----------|-------------|--------------|
| macOS | `ltl_static-binary_macos-arm64` | Apple Silicon |
| Ubuntu | `ltl_static-binary_ubuntu-amd64` | x86_64 |
| Ubuntu | `ltl_static-binary_ubuntu-arm64` | ARM64 |
| Windows | `ltl_static-binary_windows-amd64.exe` | x86_64 |

## Workflow Structure

```
Tag Push (v*) or Manual Trigger
     │
     ├── build-macos (macos-latest, ARM64)
     │
     ├── build-ubuntu (matrix: amd64, arm64 via Docker+QEMU)
     │
     └── build-windows (Docker + Wine on ubuntu-latest)
              │
              ▼
         release (attach all binaries to GitHub Release)
                 (only runs on tag push, not manual trigger)
```

## Design Decisions

### Trigger Strategy

**Decision**: Trigger on version tags (`v*`) and `workflow_dispatch`.

**Rationale**:
- Builds are resource-intensive
- Only release versions need official binaries
- `workflow_dispatch` allows testing without creating tags
- Developers can run local builds for testing

### macOS Build

**Decision**: Build only ARM64 using `macos-latest` (free runner).

**Rationale**:
- Intel macOS runners (`-large` variants) require paid GitHub plan
- ARM64 covers modern Mac hardware (Apple Silicon)
- Users with Intel Macs can use Ubuntu or Windows binaries, or build locally

### Ubuntu Architecture Matrix

**Decision**: Use matrix strategy for amd64 and arm64.

```yaml
matrix:
  arch: [amd64, arm64]
```

**Rationale**:
- amd64 runs natively on GitHub runners
- arm64 uses QEMU emulation via `docker/setup-qemu-action`
- Covers both common server architectures

### Windows Build Approach

**Decision**: Use existing Docker + Wine approach on ubuntu-latest.

**Rationale**:
- Windows runners are expensive/limited
- Docker + Wine approach already proven
- Consistent with existing build scripts

### Release Attachment

**Decision**: Only attach to releases on tag push, not manual trigger.

**Rationale**:
- Manual triggers are for testing
- Avoids polluting releases with test builds
- Prerelease detection via tag format (contains `-`)

### Release Notes

**Decision**: Require release notes in `releases/` folder for every release.

**Mechanism**:
1. Workflow checks for `releases/v{version}.md` (e.g., `releases/v0.8.2.md`)
2. If not found, workflow fails with error message
3. Release notes content is used as GitHub Release body

**Rationale**:
- Ensures every release has documented changes
- Version-specific files prevent stale notes from being reused
- Clear file naming convention matches tag names
- Centralized location keeps release history organized

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `.github/workflows/release-build.yml` | Created | Main workflow file |
| `build/macos-package.sh` | Updated | Added arch parameter, verification |
| `build/ubuntu-package.sh` | Updated | Removed `-it`, added arch parameter, verification |
| `features/ci-build.md` | Updated | This document (renamed from macos-ci-build.md) |
| `CLAUDE.md` | Updated | Added CI build documentation |

## Implementation Checklist

- [x] Create `.github/workflows/` directory
- [x] Create `release-build.yml` workflow file
- [x] Configure workflow triggers (version tags + workflow_dispatch)
- [x] Configure macOS ARM64 build
- [x] Set up Perl environment for macOS
- [x] Install PAR::Packer and dependencies
- [x] Build macOS executable with `pp`
- [x] Configure Ubuntu matrix for both architectures
- [x] Set up QEMU for arm64 Linux builds
- [x] Build Ubuntu executables via Docker
- [x] Build Windows executable via Docker + Wine
- [x] Verify builds run and output version
- [x] Upload artifacts with architecture-specific names
- [x] Attach all binaries to GitHub Release
- [x] Update build scripts with arch parameters
- [x] Update CLAUDE.md with CI documentation

## Testing

### Manual Testing Steps

1. Push changes to feature branch
2. Manually trigger workflow: `gh workflow run release-build.yml`
3. Verify all 4 jobs complete successfully
4. Verify all 4 artifacts uploaded
5. Create test tag `v0.8.2-test` and verify release attachment
6. Download and test binaries on each platform
7. Verify release notes appear correctly

### Verification Commands

```bash
# Trigger manual build
gh workflow run release-build.yml

# Watch workflow progress
gh run watch

# List artifacts from latest run
gh run view --log

# Download artifacts
gh run download <run-id>
```

## Acceptance Criteria

- [x] Pushing `v*` tag triggers workflow automatically
- [x] ARM64 binary builds successfully on `macos-latest` runner
- [x] Ubuntu amd64 binary builds successfully
- [x] Ubuntu arm64 binary builds successfully via QEMU
- [x] Windows binary builds successfully via Docker + Wine
- [x] All 4 binaries attached to GitHub Release
- [x] Build verification confirms executables run
- [x] Manual trigger works without creating release

## References

- [GitHub Actions macOS runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [shogo82148/actions-setup-perl](https://github.com/marketplace/actions/setup-perl-environment)
- [docker/setup-qemu-action](https://github.com/docker/setup-qemu-action)
- [PAR::Packer](https://metacpan.org/pod/PAR::Packer)
- [actions/upload-artifact v4](https://github.com/actions/upload-artifact)
- [softprops/action-gh-release](https://github.com/softprops/action-gh-release)
