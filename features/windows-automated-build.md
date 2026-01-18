# Feature Requirements: Windows Automated Build

## Branch
`windows-automated-build`

## Overview
Automate the Windows static binary build process using Rancher Desktop with Wine and Strawberry Perl, enabling fully scripted builds from a Linux environment without manual intervention. The x86_64 (amd64) build works on both native x64 and ARM64 Windows devices.

## Background / Problem Statement
The current `windows-package.sh` script has several issues preventing full automation:
- Contains `sleep infinity` at the end which blocks script completion
- Lacks proper error handling and exit status reporting
- Output path handling inconsistencies
- Missing verification of the built executable

The goal is to have a fully automated Windows build that can be triggered from CI/CD or command line on Linux/macOS, similar to the Ubuntu build process.

## Goals
- Fully automated Windows x86_64 static binary build with no manual intervention
- Consistent build artifact naming and placement
- Proper exit status for CI/CD integration
- Build verification using `ltl -version` to confirm executable runs

## Requirements

### Functional Requirements
1. Windows x86_64 build completes without manual intervention
2. Build script exits with proper status code (0 for success, non-zero for failure)
3. Built executable is verified by running `ltl -version` via Wine
4. Consistent output naming: `ltl_static-binary_windows-amd64.exe`

### Non-Functional Requirements
- Build must work on Linux host with Rancher Desktop installed
- Build must work on macOS host with Rancher Desktop
- Reasonable build time (under 15 minutes on typical hardware)
- Clear error messages on failure

## User Stories
- As a developer, I want to run `./build/windows-package.sh` and have it produce a working Windows executable without any manual steps
- As a CI/CD system, I want the build script to exit with proper status codes so I can detect build failures
- As a release manager, I want consistent artifact naming for predictable deployment

## Acceptance Criteria
- [x] `./build/windows-package.sh` completes without hanging
- [x] Script exits with code 0 on success, non-zero on failure
- [x] Built executable verified by running `wine ltl.exe -version` and confirming version output
- [ ] Build works on Linux Rancher Desktop host
- [x] Build works on macOS Rancher Desktop host
- [x] ARM64 Windows compatibility documented (x86_64 build runs via emulation)

## Technical Considerations

### Architecture: Wine + Strawberry Perl Approach
The build uses a Rancher Desktop container running Ubuntu with Wine to execute Strawberry Perl (a Windows Perl distribution). This allows:
- Running Windows perl.exe and pp.exe via Wine
- Using Windows-native PAR::Packer to create proper Windows executables
- Building from any Linux/macOS host without a Windows machine

### Key Components
1. **Rancher Desktop base**: Ubuntu 20.04 (oldest LTS for glibc compatibility)
2. **Wine**: Executes Windows binaries in Linux
3. **Strawberry Perl Portable**: Windows Perl distribution with full toolchain (gcc, gmake)
4. **PAR::Packer (pp)**: Creates standalone executable from Perl script

### Strawberry Perl Source
- Primary: GitHub Releases API (`StrawberryPerl/Perl-Dist-Strawberry`)
- Fallback: SourceForge mirror
- Asset pattern: `*64bit-portable.zip`

### ARM64 Windows Compatibility
The x86_64 (amd64) build works on ARM64 Windows devices:
- **No native ARM64 build needed**: Windows 11 on ARM includes an excellent x86_64 emulation layer that runs the amd64 executable seamlessly
- **Strawberry Perl limitation**: Strawberry Perl does not provide native ARM64 Windows builds ([GitHub issue #28](https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/28), [issue #218](https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/218))
- **Recommendation**: Use `ltl_static-binary_windows-amd64.exe` on all Windows devices (x64 and ARM64)

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
- Rancher Desktop installed (Linux) or Rancher Desktop installed (macOS)
- Rancher Desktop daemon running
- Repository cloned with cpanfile generated

#### Test Scenarios

##### Scenario 1: Successful Build on Linux
**Environment**: Linux host with Rancher Desktop
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
1. Start Rancher Desktop and ensure Rancher Desktop compatibility mode is enabled
2. Verify docker command works: `docker --version`
3. Ensure cpanfile exists: `ls build/cpanfile`
4. Run build: `./build/windows-package.sh`

**Expected Results**:
- Same as Scenario 1

##### Scenario 3: Missing Rancher Desktop
**Environment**: Host without Rancher Desktop installed
**Steps**:
1. Uninstall or stop Rancher Desktop
2. Run build: `./build/windows-package.sh`

**Expected Results**:
- Script exits immediately with error
- Error message: `[error] Container runtime not found. Please install Rancher Desktop: https://rancherdesktop.io/`
- Exit code is 1

##### Scenario 4: Missing cpanfile
**Environment**: Linux/macOS with Rancher Desktop
**Steps**:
1. Remove or rename cpanfile: `mv build/cpanfile build/cpanfile.bak`
2. Run build: `./build/windows-package.sh`
3. Restore cpanfile: `mv build/cpanfile.bak build/cpanfile`

**Expected Results**:
- Script exits with error
- Error message: `[error] Missing build/cpanfile - run ./build/generate-cpanfile.sh first`
- Exit code is 1

##### Scenario 5: Network Failure During Strawberry Perl Download
**Environment**: Linux/macOS with Rancher Desktop but no internet access
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
1. Configure CI job with Rancher Desktop support
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

## Implementation Status

### Completed
- [x] Created feature branch `windows-automated-build`
- [x] Removed `sleep infinity` that blocked script completion
- [x] Removed `-it` flag to allow non-interactive execution
- [x] Added Rancher Desktop availability check with clear error message
- [x] Added cpanfile pre-check before build
- [x] Added numbered progress steps (1/7 through 7/7)
- [x] Added build verification using `wine ltl.exe -version`
- [x] Documented ARM64 limitations (Strawberry Perl x64 only)
- [x] Created comprehensive test plan with 7 scenarios
- [x] Fixed platform-specific module loading (Proc::ProcessTable vs Win32::Process::Info)
- [x] Created platform-specific cpanfiles (cpanfile for Unix, cpanfile.windows for Windows)
- [x] Updated generate-cpanfile.sh to support platform argument
- [x] Added explicit -M flags for dynamically loaded DateTime modules
- [x] Configured Wine PATH for Strawberry Perl toolchain (gmake, gcc)
- [x] Verified successful build on macOS with Rancher Desktop

### Commits
1. `1dd376f` - Add automated Windows build with verification
2. `e552c2d` - Add Rancher Desktop check and comprehensive test plan
3. `5735aba` - Update references from Docker to Rancher Desktop
4. (pending) - Fix platform-specific modules and cpanfile generation

### Remaining
- [ ] Test Scenario 1: Successful build on Linux with Rancher Desktop
- [x] Test Scenario 2: Successful build on macOS with Rancher Desktop
- [ ] Test Scenario 6: Verify built executable on actual Windows
- [x] Update acceptance criteria checkboxes based on test results
- [ ] Commit changes and merge to main

## Next Steps (Pickup Point)

To resume testing this feature:

1. **Ensure Rancher Desktop is running**:
   ```bash
   docker --version  # Should return version info
   ```

2. **Run the build**:
   ```bash
   cd /Users/gregeva/Documents/GitHub/logtimeline
   ./build/windows-package.sh
   ```

3. **Expected output progression**:
   - `[1/7] Installing system packages...`
   - `[2/7] Initializing Wine...`
   - `[3/7] Downloading Strawberry Perl...`
   - `[4/7] Extracting Strawberry Perl...`
   - `[5/7] Installing PAR::Packer...`
   - `[6/7] Installing dependencies from cpanfile.windows...`
   - `[7/7] Building Windows executable...`
   - `Build Verification` section with version output
   - `BUILD SUCCESSFUL: ltl_static-binary_windows-amd64.exe`

4. **If build succeeds**, verify the output:
   ```bash
   file ltl_static-binary_windows-amd64.exe
   # Expected: PE32+ executable (console) x86-64, for MS Windows
   ```

5. **If build fails**, check the error output and update the script as needed.

6. **Once all tests pass**, update the acceptance criteria checkboxes and merge to main.

## Notes
- The Strawberry Perl portable ZIP is ~200MB download
- Wine initialization takes some time on first run
- Full build typically takes 5-10 minutes depending on network and CPU
- cpanfile.windows must be generated before running build (run `./build/generate-cpanfile.sh`)
- The generate-cpanfile.sh script now generates both Unix and Windows cpanfiles by default
- Platform-specific modules: Unix uses Proc::ProcessTable, Windows uses Win32::Process::Info
