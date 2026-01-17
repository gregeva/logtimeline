# Feature Requirements: Windows Automated Build

## Branch
`windows-automated-build`

## Overview
Automate the Windows static binary build process using Docker with Wine and Strawberry Perl, enabling fully scripted builds from a Linux environment without manual intervention. Support both amd64 and arm64 architectures.

## Background / Problem Statement
The current `windows-package.sh` script has several issues preventing full automation:
- Contains `sleep infinity` at the end which blocks script completion
- Lacks proper error handling and exit status reporting
- No ARM64 Windows support
- Output path handling inconsistencies
- Missing verification of the built executable

The goal is to have a fully automated Windows build that can be triggered from CI/CD or command line on Linux/macOS, similar to the Ubuntu build process.

## Goals
- Fully automated Windows amd64 static binary build with no manual intervention
- Investigate and document ARM64 Windows build feasibility
- Consistent build artifact naming and placement
- Proper exit status for CI/CD integration
- Build verification using `ltl -version` to confirm executable runs

## Requirements

### Functional Requirements
1. Windows amd64 build completes without manual intervention
2. Build script exits with proper status code (0 for success, non-zero for failure)
3. Built executable is verified by running `ltl -version` via Wine
4. Support architecture selection via variable or parameter
5. Consistent output naming: `ltl_static-binary_windows-{architecture}.exe`

### Non-Functional Requirements
- Build must work on Linux host with Docker installed
- Build must work on macOS host with Rancher Desktop
- Reasonable build time (under 15 minutes on typical hardware)
- Clear error messages on failure

## User Stories
- As a developer, I want to run `./build/windows-package.sh` and have it produce a working Windows executable without any manual steps
- As a CI/CD system, I want the build script to exit with proper status codes so I can detect build failures
- As a release manager, I want consistent artifact naming for predictable deployment

## Acceptance Criteria
- [ ] `./build/windows-package.sh` completes without hanging
- [ ] Script exits with code 0 on success, non-zero on failure
- [ ] Built executable verified by running `wine ltl.exe -version` and confirming version output
- [ ] Build works on Linux Docker host
- [ ] Build works on macOS Rancher Desktop host
- [ ] ARM64 support documented (feasibility, limitations)

## Technical Considerations

### Architecture: Wine + Strawberry Perl Approach
The build uses a Docker container running Ubuntu with Wine to execute Strawberry Perl (a Windows Perl distribution). This allows:
- Running Windows perl.exe and pp.exe via Wine
- Using Windows-native PAR::Packer to create proper Windows executables
- Building from any Linux/macOS host without a Windows machine

### Key Components
1. **Docker base**: Ubuntu 20.04 (oldest LTS for glibc compatibility)
2. **Wine**: Executes Windows binaries in Linux
3. **Strawberry Perl Portable**: Windows Perl distribution with full toolchain (gcc, gmake)
4. **PAR::Packer (pp)**: Creates standalone executable from Perl script

### Strawberry Perl Source
- Primary: GitHub Releases API (`StrawberryPerl/Perl-Dist-Strawberry`)
- Fallback: SourceForge mirror
- Asset pattern: `*64bit-portable.zip`

### ARM64 Windows Considerations
ARM64 Windows support is limited:
- Strawberry Perl does not currently provide ARM64 builds
- Wine on ARM64 Linux can emulate x86_64 Windows (via qemu-user)
- Most ARM64 Windows devices run x64 emulation layer anyway
- Recommendation: Focus on x64 which runs natively or emulated on ARM64 Windows

### Build Output
- Location: Repository root (one level up from build/)
- Naming: `ltl_static-binary_windows-amd64.exe`
- Type: PE32+ executable (console) x86-64, for MS Windows

### Build Verification
After building, the script must verify the executable works by running:
```bash
wine /path/to/${PACKAGE_NAME}.exe -version
```
This should output the version number (e.g., "0.7.3"). If this command fails or produces no version output, the build should be considered failed.

## Out of Scope
- Native Windows build (requires Windows host)
- GUI installer/MSI packaging
- Code signing
- Cross-compilation without Wine (would require significant toolchain work)

## Testing Requirements

### Test Plan

#### Prerequisites
- Docker installed (Linux) or Rancher Desktop installed (macOS)
- Docker daemon running
- Repository cloned with cpanfile generated

#### Test Scenarios

##### Scenario 1: Successful Build on Linux
**Environment**: Linux host with Docker
**Steps**:
1. Ensure cpanfile exists: `ls build/cpanfile`
2. Run build: `./build/windows-package.sh`
3. Observe progress through steps 1/7 to 7/7
4. Wait for build verification step

**Expected Results**:
- Script completes without error
- Exit code is 0
- Output file `ltl_static-binary_windows-amd64.exe` exists in repo root
- `file ltl_static-binary_windows-amd64.exe` shows: `PE32+ executable (console) x86-64, for MS Windows`
- Build verification shows version output (e.g., "0.7.3")
- Final message: "BUILD SUCCESSFUL: ltl_static-binary_windows-amd64.exe"

##### Scenario 2: Successful Build on macOS with Rancher Desktop
**Environment**: macOS host with Rancher Desktop
**Steps**:
1. Start Rancher Desktop and ensure Docker compatibility mode is enabled
2. Verify docker command works: `docker --version`
3. Ensure cpanfile exists: `ls build/cpanfile`
4. Run build: `./build/windows-package.sh`

**Expected Results**:
- Same as Scenario 1

##### Scenario 3: Missing Docker
**Environment**: Host without Docker installed
**Steps**:
1. Uninstall or stop Docker
2. Run build: `./build/windows-package.sh`

**Expected Results**:
- Script exits immediately with error
- Error message: `[error] Docker not found. Please install Docker (Linux) or Rancher Desktop (macOS).`
- Exit code is 1

##### Scenario 4: Missing cpanfile
**Environment**: Linux/macOS with Docker
**Steps**:
1. Remove or rename cpanfile: `mv build/cpanfile build/cpanfile.bak`
2. Run build: `./build/windows-package.sh`
3. Restore cpanfile: `mv build/cpanfile.bak build/cpanfile`

**Expected Results**:
- Script exits with error
- Error message: `[error] Missing build/cpanfile - run ./build/generate-cpanfile.sh first`
- Exit code is 1

##### Scenario 5: Network Failure During Strawberry Perl Download
**Environment**: Linux/macOS with Docker but no internet access
**Steps**:
1. Disconnect network or block github.com and sourceforge.net
2. Run build: `./build/windows-package.sh`

**Expected Results**:
- Script fails at step 3/7 (Downloading Strawberry Perl)
- Error message about download failure
- Exit code is non-zero

##### Scenario 6: Verify Built Executable on Actual Windows
**Environment**: Windows machine (physical or VM)
**Steps**:
1. Complete successful build on Linux/macOS
2. Copy `ltl_static-binary_windows-amd64.exe` to Windows machine
3. Open Command Prompt or PowerShell
4. Run: `ltl_static-binary_windows-amd64.exe -version`
5. Run: `ltl_static-binary_windows-amd64.exe -help`

**Expected Results**:
- Version number displayed (e.g., "0.7.3")
- Help text displayed
- No missing DLL errors
- No runtime errors

##### Scenario 7: CI/CD Integration Test
**Environment**: CI/CD pipeline (GitHub Actions, Jenkins, etc.)
**Steps**:
1. Configure CI job with Docker support
2. Run: `./build/windows-package.sh && echo "SUCCESS" || echo "FAILED"`
3. Archive artifact: `ltl_static-binary_windows-amd64.exe`

**Expected Results**:
- Job completes successfully
- "SUCCESS" printed
- Artifact archived

### Automated Build Verification (in-script)
The build script includes automatic verification:
```bash
# After pp builds the exe, verify it runs via Wine
wine ${PACKAGE_NAME}.exe -version
# Check exit code and verify version output is not empty
```

If the `-version` flag produces no output or the command fails, the build is marked as failed with exit code 1.

### Manual Testing Commands
```bash
# Full build
./build/windows-package.sh

# Verify output exists
ls -la ltl_static-binary_windows-amd64.exe

# Verify file type
file ltl_static-binary_windows-amd64.exe
# Expected: PE32+ executable (console) x86-64, for MS Windows

# Exit code verification
./build/windows-package.sh && echo "SUCCESS" || echo "FAILED"
```

## Documentation Requirements
- Update build_notes if necessary
- Ensure README mentions Windows build capability

## Notes
- The Strawberry Perl portable ZIP is ~200MB download
- Wine initialization takes some time on first run
- Full build typically takes 5-10 minutes depending on network and CPU
- cpanfile must be generated before running build (see `generate-cpanfile.sh`)
