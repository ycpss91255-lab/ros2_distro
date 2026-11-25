#!/usr/bin/env bats

# swc (colcon install/ workspace source helper, #28) tests.
# Moved out of .base/test/unit/bashrc_spec.bats so .base/ stays unmodified.
# In the test stage the repo bashrc is copied next to this file (see
# Dockerfile); when run from a checkout, fall back to config/shell/bashrc.

setup() {
  load "${BATS_TEST_DIRNAME}/test_helper"
  RC="${BATS_TEST_DIRNAME}/bashrc"
  [[ -f "${RC}" ]] || RC="${BATS_TEST_DIRNAME}/../../config/shell/bashrc"
}

@test "swc is defined" {
  run grep -q "^swc()" "${RC}"
  assert_success
}

@test "swc searches colcon install/ paths, not catkin devel/" {
  run grep -qE '"[.][.]/install"' "${RC}"
  assert_success
  run grep -qE '"[.]/devel"|"[.][.]/devel"' "${RC}"
  assert_failure
}

@test "swc sources ./install/setup.bash when present" {
  local tmpdir
  tmpdir="$(mktemp -d)"
  mkdir -p "${tmpdir}/install"
  printf '# stub workspace setup\n' > "${tmpdir}/install/setup.bash"
  run bash -c "source '${RC}' >/dev/null 2>&1; cd '${tmpdir}'; swc"
  assert_success
  assert_output --partial "sourced ./install/setup.bash"
  rm -rf "${tmpdir}"
}

@test "swc sources ../install/setup.bash when ./install absent" {
  local tmpdir
  tmpdir="$(mktemp -d)"
  local subdir="${tmpdir}/sub"
  mkdir -p "${subdir}" "${tmpdir}/install"
  printf '# stub workspace setup\n' > "${tmpdir}/install/setup.bash"
  run bash -c "source '${RC}' >/dev/null 2>&1; cd '${subdir}'; swc"
  assert_success
  assert_output --partial "sourced ../install/setup.bash"
  rm -rf "${tmpdir}"
}

@test "swc exits 1 and reports missing candidates when no setup.bash found" {
  local tmpdir
  tmpdir="$(mktemp -d)"
  run bash -c "source '${RC}' >/dev/null 2>&1; cd '${tmpdir}'; HOME='${tmpdir}' swc 2>&1"
  assert_failure
  assert_output --partial "No setup.bash found"
  rm -rf "${tmpdir}"
}
