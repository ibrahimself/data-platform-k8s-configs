#!/bin/bash

# CodeCommit Repository Setup Script
# This script ONLY creates the CodeCommit repository and credentials
# All K8s configurations are managed as separate YAML files

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_NAME="${REPO_NAME:-data-platform-k8s-configs}"
REPO_DESCRIPTION="${REPO_DESCRIPTION:-Data Platform Kubernetes configurations for GitOps}"
AWS_REGION="${AWS_REGION:-eu-west-3}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-399883341639}"
PROJECT_DIR="${PROJECT_DIR:-./data-platform-k8s-configs}"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Get current account ID
    CURRENT_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
    print_status "Current AWS Account: $CURRENT_ACCOUNT"
    
    print_success "Prerequisites check completed"
}

# Function to check if any CodeCommit repositories exist
check_existing_repositories() {
    print_status "Checking for existing CodeCommit repositories..."
    
    local repo_count
    repo_count=$(aws codecommit list-repositories --region "$AWS_REGION" --query 'repositories | length(@)' --output text 2>/dev/null || echo "0")
    
    if [ "$repo_count" -eq 0 ]; then
        print_warning "No existing CodeCommit repositories found in this account"
        print_warning "This may cause restrictions when creating repositories via CLI"
        return 1
    else
        print_status "Found $repo_count existing repositories - CLI creation should work"
        return 0
    fi
}

# Function to provide manual creation instructions
provide_manual_instructions() {
    print_error "Unable to create repository via CLI due to AWS account restrictions"
    echo ""
    echo -e "${YELLOW}MANUAL SETUP REQUIRED:${NC}"
    echo "======================="
    echo ""
    echo "1. Go to AWS Console: https://console.aws.amazon.com/codesuite/codecommit/repositories"
    echo "2. Click 'Create repository'"
    echo "3. Repository name: $REPO_NAME"
    echo "4. Description: $REPO_DESCRIPTION"
    echo "5. Click 'Create'"
    echo ""
    echo "After creating the repository manually, you can:"
    echo "a) Re-run this script (it will detect the existing repository)"
    echo "b) Or continue with the manual clone URL provided in the console"
    echo ""
    echo -e "${BLUE}Alternative: Use AWS CLI after manual creation:${NC}"
    echo "aws codecommit get-repository --repository-name $REPO_NAME --region $AWS_REGION"
    echo ""
}

# Function to create CodeCommit repository with enhanced error handling
create_codecommit_repo() {
    print_status "Creating CodeCommit repository: $REPO_NAME"
    
    # Check if repository already exists
    if aws codecommit get-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" &> /dev/null; then
        print_warning "Repository $REPO_NAME already exists"
        REPO_CLONE_URL=$(aws codecommit get-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" --query 'repositoryMetadata.cloneUrlHttp' --output text)
        print_success "Using existing repository"
        echo "Clone URL: $REPO_CLONE_URL"
        return 0
    fi
    
    # Check if any repositories exist (to predict CLI restrictions)
    if ! check_existing_repositories; then
        print_warning "Attempting to create repository despite potential restrictions..."
    fi
    
    # Attempt to create the repository with enhanced error handling
    local create_output
    local create_exit_code
    
    create_output=$(aws codecommit create-repository \
        --repository-name "$REPO_NAME" \
        --repository-description "$REPO_DESCRIPTION" \
        --region "$AWS_REGION" 2>&1) || create_exit_code=$?
    
    if [ "${create_exit_code:-0}" -ne 0 ]; then
        # Check for specific error types
        if echo "$create_output" | grep -q "OperationNotAllowedException.*not allowed because there is no existing repository"; then
            print_error "Repository creation blocked: No existing repositories in account"
            provide_manual_instructions
            return 1
        elif echo "$create_output" | grep -q "RepositoryNameExistsException"; then
            print_warning "Repository $REPO_NAME already exists (race condition detected)"
            REPO_CLONE_URL=$(aws codecommit get-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" --query 'repositoryMetadata.cloneUrlHttp' --output text)
            print_success "Using existing repository"
            echo "Clone URL: $REPO_CLONE_URL"
            return 0
        elif echo "$create_output" | grep -q "AccessDeniedException\|UnauthorizedOperation"; then
            print_error "Insufficient permissions to create CodeCommit repository"
            echo "Required permissions:"
            echo "- codecommit:CreateRepository"
            echo "- codecommit:GetRepository"
            echo "- codecommit:ListRepositories"
            return 1
        else
            print_error "Unknown error creating repository:"
            echo "$create_output"
            return 1
        fi
    fi
    
    # Parse successful response
    REPO_CLONE_URL=$(echo "$create_output" | jq -r '.repositoryMetadata.cloneUrlHttp')
    print_success "Repository created successfully"
    echo "Clone URL: $REPO_CLONE_URL"
}

# Function to create or get CodeCommit credentials
setup_codecommit_credentials() {
    print_status "Setting up CodeCommit credentials..."
    
    # Get current user
    local iam_user
    iam_user=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
    
    # Check if this is an assumed role (which can't have service-specific credentials)
    if aws sts get-caller-identity --query 'Arn' --output text | grep -q ":assumed-role/"; then
        print_warning "You are using an assumed role. Service-specific credentials cannot be created."
        print_status "Using git-remote-codecommit instead..."
        
        # Check if git-remote-codecommit is available
        if pip3 show git-remote-codecommit &> /dev/null; then
            print_success "git-remote-codecommit is already installed"
        else
            print_status "Installing git-remote-codecommit..."
            if command -v pip3 &> /dev/null; then
                pip3 install --user git-remote-codecommit
                print_success "git-remote-codecommit installed"
            else
                print_warning "pip3 not found. Please install git-remote-codecommit manually:"
                echo "pip install git-remote-codecommit"
            fi
        fi
        
        # Use codecommit:// URL instead
        if [ -n "${REPO_CLONE_URL:-}" ]; then
            CODECOMMIT_URL="codecommit::$AWS_REGION://$REPO_NAME"
            echo "Use this URL for cloning: $CODECOMMIT_URL"
        fi
        return 0
    fi
    
    # Check if service-specific credentials already exist
    local existing_creds
    existing_creds=$(aws iam list-service-specific-credentials \
        --user-name "$iam_user" \
        --service-name codecommit.amazonaws.com \
        --query 'ServiceSpecificCredentials[0]' \
        --output json 2>/dev/null || echo "null")
    
    if [ "$existing_creds" != "null" ]; then
        print_warning "CodeCommit credentials already exist for user $iam_user"
        local codecommit_username
        codecommit_username=$(echo "$existing_creds" | jq -r '.ServiceUserName')
        print_warning "Username: $codecommit_username"
        print_warning "To create new credentials, first delete the existing ones"
    else
        # Create new credentials
        print_status "Creating new CodeCommit credentials for user $iam_user"
        local new_creds
        new_creds=$(aws iam create-service-specific-credential \
            --user-name "$iam_user" \
            --service-name codecommit.amazonaws.com)
        
        local codecommit_username codecommit_password
        codecommit_username=$(echo "$new_creds" | jq -r '.ServiceSpecificCredential.ServiceUserName')
        codecommit_password=$(echo "$new_creds" | jq -r '.ServiceSpecificCredential.ServicePassword')
        
        # Save credentials to a secure file
        cat > codecommit-credentials.txt << EOF
CodeCommit Credentials
======================
Repository: $REPO_NAME
Clone URL: $REPO_CLONE_URL
Username: $codecommit_username
Password: $codecommit_password

IMPORTANT: Save these credentials securely and delete this file after use!
EOF
        chmod 600 codecommit-credentials.txt
        
        print_success "Credentials created and saved to codecommit-credentials.txt"
        print_warning "IMPORTANT: Save the password securely - it cannot be retrieved again!"
    fi
}

# Function to create directory structure
create_directory_structure() {
    print_status "Creating directory structure..."
    
    # Create main directory
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # Create subdirectories
    mkdir -p airflow
    mkdir -p argocd
    mkdir -p dremio
    mkdir -p monitoring
    mkdir -p spark
    mkdir -p scripts
    
    print_success "Directory structure created"
}

# Function to create README
create_readme() {
    cat > README.md << 'EOF'
# Data Platform K8s Configs

This repository contains Kubernetes configurations for the Data Platform, managed via GitOps with ArgoCD.

## Repository Structure

```
data-platform-k8s-configs/
├── airflow/           # Apache Airflow Helm values
├── argocd/           # ArgoCD applications and projects
├── dremio/           # Dremio Enterprise Helm values
├── monitoring/       # Prometheus stack Helm values
├── spark/            # Spark Operator Helm values
└── scripts/          # Helper scripts
```

## Setup Instructions

1. **Update Configuration Files**
   - Each directory contains a `values.yaml` file with the Helm chart configuration
   - Review and update any sensitive values (passwords, API keys, etc.)

2. **Apply ArgoCD Applications**
   ```bash
   kubectl apply -f argocd/
   ```

3. **Monitor Deployment**
   - Access ArgoCD UI to monitor application deployment
   - Check application health and sync status

## GitOps Workflow

All changes should be made via pull requests:
1. Create a feature branch
2. Make your changes
3. Commit and push
4. Create a pull request
5. After review and merge, ArgoCD will automatically sync

## Security Notes

- Never commit sensitive values (passwords, keys) directly
- Use Kubernetes secrets or external secret management
- All service accounts use IRSA for AWS access

## Support

For issues or questions, please create an issue in this repository.
EOF
}

# Function to create .gitignore
create_gitignore() {
    cat > .gitignore << 'EOF'
# Credentials
codecommit-credentials.txt
*.pem
*.key
*-secret.yaml
*-secrets.yaml
credentials*
secrets*

# Temporary files
*.tmp
*.temp
*.bak
*.swp
*~

# OS files
.DS_Store
Thumbs.db

# IDE files
.idea/
.vscode/
*.iml

# Logs
*.log
logs/

# Helm
*.tgz
charts/
EOF
}

# Function to create initial git repository
initialize_git_repo() {
    print_status "Initializing git repository..."
    
    git init
    git add README.md .gitignore
    git commit -m "Initial commit: Repository structure"
    
    # Configure git based on authentication method
    if [ -n "${CODECOMMIT_URL:-}" ]; then
        # Using git-remote-codecommit
        print_status "Configuring git for codecommit:// URL"
        git remote add origin "$CODECOMMIT_URL"
    elif [ -n "${REPO_CLONE_URL:-}" ]; then
        # Using HTTPS with credentials
        print_status "Configuring git credential helper for CodeCommit"
        git config credential.helper '!aws codecommit credential-helper $@'
        git config credential.UseHttpPath true
        git remote add origin "$REPO_CLONE_URL"
    else
        print_warning "No repository URL available - skipping remote setup"
        return 0
    fi
    
    print_success "Git repository initialized"
}

# Function to create configuration info file
create_config_info() {
    cat > CONFIG_INFO.txt << EOF
Data Platform Configuration Information
======================================
Generated: $(date)

AWS Infrastructure:
------------------
Account ID: $AWS_ACCOUNT_ID
Region: $AWS_REGION
CodeCommit Repository: $REPO_NAME
Repository URL: ${REPO_CLONE_URL:-"Not available - manual creation required"}
CodeCommit URL: ${CODECOMMIT_URL:-"Not applicable"}

Next Steps:
-----------
1. Copy the YAML configuration files to their respective directories
2. Update any placeholder values with your actual configuration
3. Commit and push the changes:
   git add .
   git commit -m "Add platform configurations"
   git push -u origin main

4. Apply ArgoCD applications:
   kubectl apply -f argocd/

Important Files to Create:
-------------------------
- airflow/values.yaml
- argocd/applications.yaml
- argocd/project.yaml
- dremio/values.yaml
- monitoring/values.yaml
- spark/values.yaml

Note: Example YAML files are provided separately.
EOF
}

# Main execution with better error handling
main() {
    print_status "Starting CodeCommit repository setup..."
    echo ""
    
    # Run setup steps with error handling
    check_prerequisites || exit 1
    
    # Try to create repository, but continue even if it fails
    if ! create_codecommit_repo; then
        print_warning "Repository creation failed, but continuing with local setup..."
        print_status "You can manually create the repository and re-run this script later"
    fi
    
    # Continue with credential setup only if we have a repository
    if [ -n "${REPO_CLONE_URL:-}${CODECOMMIT_URL:-}" ]; then
        setup_codecommit_credentials
    else
        print_warning "Skipping credential setup - no repository URL available"
    fi
    
    # Always create local structure
    create_directory_structure
    create_readme
    create_gitignore
    create_config_info
    
    # Initialize git repo if possible
    if [ -n "${REPO_CLONE_URL:-}${CODECOMMIT_URL:-}" ]; then
        initialize_git_repo
    else
        print_status "Initializing local git repository only..."
        git init
        git add README.md .gitignore CONFIG_INFO.txt
        git commit -m "Initial commit: Repository structure"
        print_warning "Remote repository not configured - add it manually later"
    fi
    
    # Print summary
    echo ""
    print_success "Setup completed!"
    echo ""
    echo "Repository Details:"
    echo "==================="
    echo "Name: $REPO_NAME"
    echo "Region: $AWS_REGION"
    if [ -n "${REPO_CLONE_URL:-}" ]; then
        echo "HTTPS URL: $REPO_CLONE_URL"
    fi
    if [ -n "${CODECOMMIT_URL:-}" ]; then
        echo "CodeCommit URL: $CODECOMMIT_URL"
    fi
    if [ -z "${REPO_CLONE_URL:-}${CODECOMMIT_URL:-}" ]; then
        echo "Status: Manual repository creation required"
    fi
    echo ""
    echo "Next Steps:"
    echo "==========="
    if [ -z "${REPO_CLONE_URL:-}${CODECOMMIT_URL:-}" ]; then
        echo "1. Create repository manually in AWS Console:"
        echo "   https://console.aws.amazon.com/codesuite/codecommit/repositories"
        echo "2. Re-run this script to complete setup"
    else
        echo "1. Check codecommit-credentials.txt for your Git credentials (if newly created)"
        echo "2. Copy the provided YAML files to their respective directories"
        echo "3. Update the configuration values in each YAML file"
        echo "4. Commit and push your changes"
        echo "5. Apply the ArgoCD applications"
    fi
    echo ""
    if [ -f "codecommit-credentials.txt" ]; then
        print_warning "Remember to save your credentials securely and delete codecommit-credentials.txt!"
    fi
    echo ""
}

# Run main function
main "$@"