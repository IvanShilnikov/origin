#!/bin/bash

set -e
set -o nounset
set -o pipefail

OS_ROOT=$(dirname "${BASH_SOURCE}")/..
source "${OS_ROOT}/hack/common.sh"

cd "${OS_ROOT}"

echo "===== Verifying Generated Conversions ====="
echo "Building genconversion binary..."
if ! buildout=`"${OS_ROOT}/hack/build-go.sh" cmd/genconversion 2>&1`
then
  echo "FAILURE: Building genconversion binary failed:"
  echo "$buildout"
  exit 1
else
  echo "$buildout" | sed 's/^/   /'
fi

genconversion="${OS_ROOT}/_output/local/go/bin/genconversion"

echo "   Verifying genconversion binary..."
if [[ ! -x "$genconversion" ]]; then
  {
    echo "FAILURE: It looks as if you don't have a compiled conversion binary."
    echo "If you are running from a clone of the git repo, please run:"
    echo "'./hack/build-go.sh cmd/genconversion'."
  } >&2
  exit 1
fi

APIROOT_REL="pkg/api"
APIROOT="${OS_ROOT}/${APIROOT_REL}"
TMP_APIROOT_REL="_output/verify-generated-conversions"
TMP_APIROOT="${OS_ROOT}/${TMP_APIROOT_REL}/${APIROOT_REL}"

echo "Generating fresh conversions..."
if ! output=`${OS_ROOT}/hack/update-generated-conversions.sh ${TMP_APIROOT_REL} 2>&1`
then
  echo "FAILURE: Generation of fresh conversions failed:"
  echo "$output"
  exit 1
fi

rsync -au "${APIROOT}" "${TMP_APIROOT}/.."

echo "Diffing current conversions against freshly generated conversions..."
ret=0
diff -Naupr -I 'Auto generated by' "${APIROOT}" "${TMP_APIROOT}" || ret=$?
rm -rf "${TMP_APIROOT}"
if [[ $ret -eq 0 ]]
then
  echo "SUCCESS: Generated conversions up to date."
else
  echo "FAILURE: Generated conversions out of date. Please run hack/update-generated-conversions.sh"
  exit 1
fi

# ex: ts=2 sw=2 et filetype=sh
