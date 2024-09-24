# shellcheck shell=bash disable=SC2154,SC2164

# We replace these
export dontCargoBuild=true
export dontCargoInstall=true

tauriBuildHook() {
    echo "Executing tauriBuildHook"

    runHook preBuild

    ## The following is lifted from rustPlatform.cargoBuildHook
    ## As we're replacing it, we should also be respecting its options.

    # Account for running outside of mkRustPackage where this may not be set
    cargoBuildType="${cargoBuildType:-release}"

    # Let stdenv handle stripping, for consistency and to not break
    # separateDebugInfo.
    export "CARGO_PROFILE_${cargoBuildType@U}_STRIP"=false

    local cargoFlagsArray=(
        "-j" "$NIX_BUILD_CORES"
        "--target" "@rustHostPlatformSpec@"
        "--offline"
    )
    local tauriFlagsArray=(
        "--bundles" "${tauriBundleType:-@defaultTauriBundleType@}"
        "--target" "@rustHostPlatformSpec@"
    )

    # https://github.com/tauri-apps/tauri/issues/10190 if fixed so we can default to `--target-dir` 
    if [ -n "${buildAndTestSubdir-}" ]; then
        cargoFlagsArray+=("--target-dir" "$(pwd)/target")
    fi

    if [ "${cargoBuildType}" != "debug" ]; then
        cargoFlagsArray+=("--profile" "${cargoBuildType}")
    fi

    if [ -n "${cargoBuildNoDefaultFeatures-}" ]; then
        cargoFlagsArray+=("--no-default-features")
    fi

    if [ -n "${cargoBuildFeatures-}" ]; then
        cargoFlagsArray+=("--features=$(concatStringsSep "," cargoBuildFeatures)")
    fi

    concatTo cargoFlagsArray cargoBuildFlags

    if [ "${cargoBuildType:-}" == "debug" ]; then
        tauriFlagsArray+=("--debug")
    fi

    concatTo tauriFlagsArray tauriBuildFlags

    echoCmd 'cargo-tauri.hook cargoFlags' "${cargoFlagsArray[@]}"
    echoCmd 'cargo-tauri.hook tauriFlags' "${tauriFlagsArray[@]}"

    @setEnv@ cargo tauri build "${tauriFlagsArray[@]}" -- "${cargoFlagsArray[@]}"

    if [ -n "${buildAndTestSubdir-}" ]; then
        popd
    fi

    runHook postBuild

    echo "Finished tauriBuildHook"
}

# TODO: Allow this to be individually enabled in the upstream hook
# Lifted from cargoInstallHook
tauriInstallPostBuildHook() {
    echo "Executing cargoInstallPostBuildHook"

    releaseDir=target/@targetSubdirectory@/$cargoBuildType
    tmpDir="$releaseDir-tmp"

    mkdir -p "$tmpDir"
    cp -r "${releaseDir}"/* "$tmpDir"/

    echo "Finished cargoInstallPostBuildHook"
}

tauriInstallHook() {
    echo "Executing tauriInstallHook"

    runHook preInstall

    # rename the output dir to a architecture independent one
    releaseDir=target/@targetSubdirectory@/$cargoBuildType
    tmpDir="${releaseDir}-tmp"

    @installScript@

    runHook postInstall

    echo "Finished tauriInstallHook"
}

if [ -z "${dontTauriBuild:-}" ] && [ -z "${buildPhase:-}" ]; then
    buildPhase=tauriBuildHook
fi

if [ -z "${dontTauriInstall:-}" ] && [ -z "${installPhase:-}" ]; then
    installPhase=tauriInstallHook
    postBuildHooks+=(tauriInstallPostBuildHook)
fi
