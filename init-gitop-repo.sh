#!/bin/bash
set -euo pipefail

#######################################
# COLORS
#######################################
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_RESET='\033[0m'

print_success()   { printf "${COLOR_GREEN}%s${COLOR_RESET}\n" "$1"; }
print_fail()      { printf "${COLOR_RED}%s${COLOR_RESET}\n" "$1"; }
print_info()      { printf "${COLOR_YELLOW}%s${COLOR_RESET}\n" "$1"; }
print_warning()   { printf "${COLOR_YELLOW}%s${COLOR_RESET}\n" "$1"; }
print_separator() { echo "=========================================================================="; }

#######################################
# DEFAULTS
#######################################
DEFAULT_BRANCH="staging-gitops-template"
USER_INPUT=false

#######################################
# HELP / USAGE
#######################################
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b, --branch <name>    Specify the branch to use"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "If no branch is given, the default '${DEFAULT_BRANCH}' will be used."
    echo ""
    echo "Example:"
    echo "  $0 --branch staging"
    echo "  $0 -b my-feature-branch"
}

#######################################
# PARSE USER INPUT
#######################################
user_input() {
    BRANCH_NAME="${DEFAULT_BRANCH}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b|--branch)
                BRANCH_NAME="${2}"
                USER_INPUT=true
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    if [[ "$USER_INPUT" == false ]]; then
        print_warning "No branch selected. Using default branch: ${BRANCH_NAME}"
        print_success "You can use these instructions to select custom branch"
        sleep 2
        usage
        sleep 5
    else
        print_info "Using provided branch: ${BRANCH_NAME}"
    fi
    print_separator    
}

#######################################
# MAIN SCRIPT
#######################################
main() {
    user_input "$@"
    
    # Check if templates.sed exists
    if [[ ! -f "templates.sed" ]]; then
        print_fail "Error: templates.sed not found in current directory!"
        exit 1
    fi

    # Apply sed templates
    print_info "Updating Branch name in  templates.sed"
    sed -i "/%branch-name%/s|\"[^\"]*\"|\"${BRANCH_NAME}\"|" templates.sed

    print_info "Applying templates.sed to *.yaml and *.yml files..."
    find . -type f \( -name "*.yaml" -o -name "*.yml" \) -exec sed -i.bak -f templates.sed {} +
    find . -type f -name "*.bak" -delete    
    print_success "Template substitution completed."

    # Check if branch already exists before creating
    if git rev-parse --verify "${BRANCH_NAME}" >/dev/null 2>&1; then
        print_fail "Error: Branch '${BRANCH_NAME}' already exists!"
        print_info "Please delete that branch with: git branch -D ${BRANCH_NAME}"
        print_info "Or choose another branch name with: $0 -b <new-branch-name>"
        exit 1
    fi

    # Create and push Git branch
    print_info "Creating new branch: ${BRANCH_NAME}"
    git checkout -b "${BRANCH_NAME}"
    git add .
    git commit -m "Initializing gitops"
    git push --set-upstream origin "${BRANCH_NAME}"
    print_success "Branch pushed successfully."
    
    print_separator
    print_success "All operations completed successfully!"
    print_separator
}

main "$@"