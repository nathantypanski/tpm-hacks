# common.sh
#
# part of tpm-blobstore

TPM_ROOT="${TPM_ROOT:-${HOME}/.tpm/tpm-blobstore}"
STORE="${TPM_ROOT}/blobs"

SCRIPT_TEMPDIR="$(mktemp -d /tmp/tpm.XXXXXXXXX)"

# extension signaling which primary key is associated with a given secret.
PRIM_EXTENSION="${PRIM_EXTENSION:-_p384}"
PRIMARY_CTX="${PRIMARY_CTX:-${STORE}/prim${PRIM_EXTENSION}.ctx}"

PCRS_TO_USE="${PCRS:-0,6,7}"
PCR_HASH_ALG="${PCR_HASH_ALG:-sha384}"
PCR_LIST="${PCR_HASH_ALG}:${PCRS_TO_USE}"

message() {
    for arg in "${@}"; do
        if [[ "${arg}" == "" ]]; then
            printf >&2 "\n"
        else
            printf >&2 ">>> %s\n" "${arg}"
        fi
    done
}

ensure_dir() {
    if [[ $# -ne 1 ]]; then
        message "ensure_dir called wiith no arguments"
        return 1
    fi
    mkdir -p "${1}"
}

fail_exists() {
    local path="${1}"
    local name="${2}"
    if [[ "${FORCE}" = "true" || ${FORCE} = '1' ]]; then
        return
    elif [[ -f "${1}" ]]; then
        message "output filename for ${2} already exists:" \
                "    '${1}'" \
                "exiting. Set FORCE to override."
        exit 201
    fi
}

ensure_dir "${TPM_ROOT}"
ensure_dir "${STORE}"
