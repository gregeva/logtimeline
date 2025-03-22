#!/bin/bash
set -e

APP_NAME="my_app"
BUILD_DIR="build"
PAR_TMP="par_tmp"

# Clean up previous builds
rm -rf "$BUILD_DIR" "$PAR_TMP"
mkdir -p "$BUILD_DIR" "$PAR_TMP"

# Stage 1: Collect dependencies from different execution paths
echo "Running ScanDeps on multiple code paths..."
pp -x -o "$PAR_TMP/stage1.pl" my_app.pl  # Extract basic dependencies

# Manually simulate different execution paths
perl -MPAR::Scanner -e 'PAR::Scanner::scan_file("my_app.pl", \%INC, @ARGV)' -- --mode1
perl -MPAR::Scanner -e 'PAR::Scanner::scan_file("my_app.pl", \%INC, @ARGV)' -- --mode2

# Consolidate dependencies
echo "Aggregating dependencies..."
find "$PAR_TMP" -name "*.pm" -exec cp --parents {} "$BUILD_DIR" \;

# Stage 2: Package into a standalone executable
echo "Building PAR package..."
pp -o "$BUILD_DIR/$APP_NAME.par" -M "$BUILD_DIR" my_app.pl
pp -o "$BUILD_DIR/$APP_NAME" -B -p -M "$BUILD_DIR" my_app.pl  # Create executable

echo "Build complete. Output in $BUILD_DIR"
