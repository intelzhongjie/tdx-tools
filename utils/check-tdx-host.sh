#!/bin/bash
#
# Check the TDX host status
#

COL_BLACK=$(tput setaf 0)
COL_RED=$(tput setaf 1)
COL_GREEN=$(tput setaf 2)
COL_YELLOW=$(tput setaf 3)
COL_LIME_YELLOW=$(tput setaf 190)
COL_POWDER_BLUE=$(tput setaf 153)
COL_BLUE=$(tput setaf 4)
COL_MAGENTA=$(tput setaf 5)
COL_CYAN=$(tput setaf 6)
COL_WHITE=$(tput setaf 7)
COL_BRIGHT=$(tput bold)
COL_NORMAL=$(tput sgr0)
COL_BLINK=$(tput blink)
COL_REVERSE=$(tput smso)
COL_UNDERLINE=$(tput smul)

#
# Report action result fail or not, if fail, then report the detail reason
# Parameters:
#   $1  -   "true" or "fail"
#   $2  -   action string
#   $3  -   reason string if fail
#
report_result() {
    if [[ $1 == "true" ]]; then
        printf '%.60s %s\n' "${2} ........................................" "${COL_GREEN}OK${COL_NORMAL}"
    else
        printf '%.60s %s\n' "${2} ........................................" "${COL_RED}FAIL${COL_NORMAL}"
        if [[ ! -z $3 ]]; then
            printf "    ${COL_RED}Reason: %s\n${COL_NORMAL}" "$3"
        fi
    fi
}

#
# Check the command exists or not
# Parameters:
#   $1  -   the command or program
#
check_cmd() {
    if ! [ -x "$(command -v $1)" ]; then
        echo "Error: $1 is not installed." >&2
        echo $2
        exit 1
    fi
}

#
# Check whether the bit 11 for MSR 0x1401, 1 means MK-TME is enabled in BIOS.
#
check_bios_enabling_mktme() {
    action="Check BIOS Enabling for MK-TME"
    reason="The bit 1 of MSR 0x982 should be 1, but got 0"

    retval=$(rdmsr -f 1:1 0x982)
    [[ $retval == "1" ]] && result="true" || result="fail"
    report_result $result "$action" "$reason"
}

#
# Check whether the bit 11 for MSR 0x1401, 1 means TDX is enabled in BIOS.
#
check_bios_enabling_tdx() {
    action="Check BIOS Enabling for TDX"
    reason="The bit 11 of MSR 1401 should be 1, but got 0"

    retval=$(rdmsr -f 11:11 0x1401)
    [[ $retval == "1" ]] && result="true" || result="fail"
    report_result $result "$action" "$reason"
}

#
# Check whether SGX is enabled in BIOS
# NOTE: please refer https://software.intel.com/sites/default/files/managed/48/88/329298-002.pdf
#
check_bios_enabling_sgx() {
    action="Check BIOS Enabling for SGX"
    reason="The bit 18 of MSR 0x3a should be 1, but got 0"

    retval=$(rdmsr -f 18:18 0x3a)
    [[ $retval == "1" ]] && result="true" || result="fail"
    report_result $result "$action" "$reason"
}

check_cmd rdmsr "Please install via apt install msr-tool (Ubuntu) or dnf install msr-tools (RHEL/CentOS)"

check_bios_enabling_mktme
check_bios_enabling_tdx
check_bios_enabling_sgx

