#!/usr/bin/env bash
#
# Run the zprezto setup + neovim config test suite inside throw-away Docker
# containers for Arch, Ubuntu and Fedora.
#
#   tests/run-docker-tests.sh                 # all three distros
#   tests/run-docker-tests.sh arch            # just Arch
#   tests/run-docker-tests.sh -d ubuntu,arch  # a subset
#   tests/run-docker-tests.sh --quick         # skip package installs / plugin sync
#   tests/run-docker-tests.sh --full fedora   # also run setup.sh end to end
#   tests/run-docker-tests.sh --shell arch    # interactive shell in the image
#
# The repo is bind-mounted read only and copied to ~/.zprezto inside the
# container, so the working tree is tested as-is (including uncommitted
# changes) and nothing on the host is modified.

set -uo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly LOG_DIR="${REPO_ROOT}/tests/.logs"
readonly ALL_DISTROS=(arch ubuntu fedora)
readonly IMAGE_PREFIX="zprezto-test"

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

MODE="default"
NVIM_SOURCE="auto"
DISTROS=()
NO_CACHE=""
BUILD_ONLY=0
SHELL_MODE=0
QUIET=0

usage() {
    cat <<EOF
Usage: ${0##*/} [options] [distro ...]

Distros: ${ALL_DISTROS[*]} all   (default: all)

Options:
  -d, --distro <list>   Comma or space separated list of distros to test.
  -q, --quick           Skip package installation and neovim plugin sync.
                        Only lints scripts, links dotfiles and starts the shells.
  -f, --full            Also run setup.sh end to end (slow; installs everything).
      --nvim <source>   auto|distro|upstream. "auto" (default) uses the distro's
                        neovim unless it is too old for the config, then falls
                        back to the official release tarball.
      --no-cache        Rebuild the Docker images from scratch.
      --build-only      Build the images and exit.
  -s, --shell           Drop into an interactive shell in the image instead of
                        running the tests (one distro only).
      --quiet           Only print the per-distro summary; full logs still go
                        to tests/.logs/<distro>.log.
  -h, --help            This message.
EOF
}

die() { echo -e "${RED}error:${NC} $*" >&2; exit 2; }

add_distros() {
    local item
    for item in ${1//,/ }; do
        if [[ "${item}" == "all" ]]; then
            DISTROS+=("${ALL_DISTROS[@]}")
        elif [[ " ${ALL_DISTROS[*]} " == *" ${item} "* ]]; then
            DISTROS+=("${item}")
        else
            die "unknown distro '${item}' (choose from: ${ALL_DISTROS[*]} all)"
        fi
    done
}

while (( $# )); do
    case "$1" in
        -d|--distro) [[ $# -ge 2 ]] || die "$1 needs a value"; add_distros "$2"; shift 2 ;;
        -q|--quick)  MODE="quick"; shift ;;
        -f|--full)   MODE="full"; shift ;;
        --nvim)      [[ $# -ge 2 ]] || die "$1 needs a value"; NVIM_SOURCE="$2"; shift 2 ;;
        --no-cache)  NO_CACHE="--no-cache"; shift ;;
        --build-only) BUILD_ONLY=1; shift ;;
        -s|--shell)  SHELL_MODE=1; shift ;;
        --quiet)     QUIET=1; shift ;;
        -h|--help)   usage; exit 0 ;;
        -*)          die "unknown option '$1' (see --help)" ;;
        *)           add_distros "$1"; shift ;;
    esac
done

case "${NVIM_SOURCE}" in
    auto|distro|upstream) ;;
    *) die "--nvim must be auto, distro or upstream" ;;
esac

(( ${#DISTROS[@]} )) || DISTROS=("${ALL_DISTROS[@]}")

# De-duplicate while preserving order (portable to bash 3.2).
_unique=()
for _d in "${DISTROS[@]}"; do
    [[ " ${_unique[*]-} " == *" ${_d} "* ]] || _unique+=("${_d}")
done
DISTROS=("${_unique[@]}")

command -v docker >/dev/null 2>&1 || die "docker is not installed or not on PATH"
docker info >/dev/null 2>&1 || die "cannot talk to the docker daemon (is Docker running?)"

if (( SHELL_MODE )) && (( ${#DISTROS[@]} != 1 )); then
    die "--shell works with exactly one distro"
fi

# archlinux:base has no arm64 build; use Arch Linux ARM there instead.
base_image_for() {
    local distro="$1" machine
    machine="$(uname -m)"
    case "${distro}" in
        arch)
            if [[ "${machine}" == "arm64" || "${machine}" == "aarch64" ]]; then
                echo "menci/archlinuxarm:base"
            else
                echo "archlinux:base"
            fi
            ;;
        ubuntu) echo "ubuntu:24.04" ;;
        fedora) echo "fedora:latest" ;;
    esac
}

build_image() {
    local distro="$1" image="${IMAGE_PREFIX}:$1" base
    base="$(base_image_for "${distro}")"
    echo -e "${BLUE}==>${NC} Building ${image} from ${base}"
    local log="${LOG_DIR}/${distro}-build.log"
    if docker build ${NO_CACHE} \
            --build-arg "BASE_IMAGE=${base}" \
            -t "${image}" \
            -f "${REPO_ROOT}/tests/docker/Dockerfile.${distro}" \
            "${REPO_ROOT}/tests/docker" >"${log}" 2>&1; then
        return 0
    fi
    echo -e "${RED}==>${NC} Build failed for ${distro}; last 40 lines of ${log}:"
    tail -40 "${log}" | sed 's/^/    | /'
    return 1
}

run_tests() {
    local distro="$1" image="${IMAGE_PREFIX}:$1"
    local log="${LOG_DIR}/${distro}.log"
    echo -e "${BLUE}==>${NC} Running tests on ${distro} (mode=${MODE}), log: ${log}"

    local -a docker_args=(
        run --rm
        --name "${IMAGE_PREFIX}-${distro}-$$"
        -v "${REPO_ROOT}:/repo:ro"
        -e "DISTRO=${distro}"
        -e "MODE=${MODE}"
        -e "NVIM_SOURCE=${NVIM_SOURCE}"
        -e "REPO_SRC=/repo"
        -e "TERM=xterm-256color"
    )

    if (( SHELL_MODE )); then
        echo -e "${YELLOW}==>${NC} Interactive shell; the repo is at /repo (read only)."
        docker "${docker_args[@]}" -it "${image}" /bin/bash
        return $?
    fi

    if (( QUIET )); then
        # tee rather than redirect, so the log is complete even when the
        # summary is all that gets printed.
        docker "${docker_args[@]}" "${image}" bash /repo/tests/container/run-tests.sh 2>&1 \
            | tee "${log}" \
            | sed -n '/------------------- summary/,$p'
        return "${PIPESTATUS[0]}"
    fi

    docker "${docker_args[@]}" "${image}" bash /repo/tests/container/run-tests.sh 2>&1 | tee "${log}"
    return "${PIPESTATUS[0]}"
}

mkdir -p "${LOG_DIR}"

# distro=result pairs; kept as a plain array for bash 3.2 compatibility.
RESULTS=()
overall=0

record() { RESULTS+=("$1=$2"); }
result_of() {
    local entry
    for entry in ${RESULTS[@]+"${RESULTS[@]}"}; do
        [[ "${entry%%=*}" == "$1" ]] && { echo "${entry#*=}"; return; }
    done
    echo "SKIPPED"
}

for distro in "${DISTROS[@]}"; do
    if ! build_image "${distro}"; then
        record "${distro}" "BUILD-FAILED"
        overall=1
        continue
    fi
    (( BUILD_ONLY )) && { record "${distro}" "BUILT"; continue; }

    if run_tests "${distro}"; then
        record "${distro}" "PASS"
    else
        record "${distro}" "FAIL"
        overall=1
    fi
done

(( SHELL_MODE )) && exit "${overall}"

echo
echo -e "${BLUE}=================== overall ===================${NC}"
for distro in "${DISTROS[@]}"; do
    result="$(result_of "${distro}")"
    case "${result}" in
        PASS|BUILT) color="${GREEN}" ;;
        *)          color="${RED}" ;;
    esac
    printf '  %-8s %b%s%b\n' "${distro}" "${color}" "${result}" "${NC}"
done
echo -e "  logs: ${LOG_DIR}"
exit "${overall}"
