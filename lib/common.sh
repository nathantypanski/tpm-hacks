# common.sh
#
# part of tpm-blobstore

TPM_ROOT="${TPM_ROOT:-${HOME}/.tpm/tpm-blobstore}"
SCRIPT_TEMPDIR="$(mktemp -d /tmp/tpm.XXXXXXXXX)"

# extension signaling which primary key is associated with a given secret.
PRIM_EXTENSION="${PRIM_EXTENSION:-_p384}"

PRIMARY_CTX="${PRIMARY_CTX:-${TPM_ROOT}/prim${PRIM_EXTENSION}.ctx}"

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
    local dir="${1}"
    mkdir -p "${TPM_ROOT}"
}

fail_exists() {
    if [[ "${FORCE}" = "true" || ${FORCE} = '1' ]]; then
        return
    elif [[ -f "${1}" ]]; then
        message "output filename already exists:" \
                "    '${1}'" \
                "exiting. Set FORCE to override."
        exit 201
    fi
}

ensure_dir "${TPM_ROOT}"
