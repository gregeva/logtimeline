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

### Automated Build Verification (in-script)
The build script itself must verify the built executable works:
```bash
# After pp builds the exe, verify it runs
wine ${PACKAGE_NAME}.exe -version
# Check exit code and output contains version number
```

### Manual Testing
```bash
# Run the build
./build/windows-package.sh

# Verify output exists
ls -la ltl_static-binary_windows-amd64.exe

# Verify file type
file ltl_static-binary_windows-amd64.exe
# Expected: PE32+ executable (console) x86-64, for MS Windows
```

### Exit Code Verification
```bash
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
