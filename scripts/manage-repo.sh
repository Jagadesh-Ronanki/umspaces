#!/bin/bash

# GitHub Repository with Submodules Manager
# Interactive script to create and manage a parent repository with submodules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PARENT_REPO_NAME=""
GITHUB_USERNAME=""
SERVICES_DIR="services"
DEFAULT_SUBMODULES=("website" "apps" "ai")

# Helper functions
print_header() {
    echo -e "\n${BLUE}=====================================
$1
=====================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " result
        result="${result:-$default}"
    else
        read -p "$prompt: " result
    fi
    
    echo "$result"
}

confirm() {
    local prompt="$1"
    local response
    read -p "$prompt (y/N): " response
    [[ "$response" =~ ^[Yy]$ ]]
}

check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install Git and try again."
        exit 1
    fi
    print_success "Git is available"
}

check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI is not installed. You'll need to create repositories manually."
        return 1
    fi
    
    if ! gh auth status &> /dev/null; then
        print_warning "GitHub CLI is not authenticated. Please run 'gh auth login' first."
        return 1
    fi
    
    print_success "GitHub CLI is available and authenticated"
    return 0
}

create_github_repo() {
    local repo_name="$1"
    local description="$2"
    local is_private="$3"
    
    local privacy_flag=""
    if [ "$is_private" = "true" ]; then
        privacy_flag="--private"
    else
        privacy_flag="--public"
    fi
    
    if gh repo create "$repo_name" --description "$description" $privacy_flag; then
        print_success "Created GitHub repository: $repo_name"
        return 0
    else
        print_error "Failed to create GitHub repository: $repo_name"
        return 1
    fi
}

setup_parent_repo() {
    print_header "Setting up Parent Repository"
    
    # Get repository details
    PARENT_REPO_NAME=$(prompt_input "Enter parent repository name" "business-services")
    GITHUB_USERNAME=$(prompt_input "Enter GitHub username/organization")
    
    local repo_description=$(prompt_input "Enter repository description" "Business services with modular architecture")
    local is_private=$(confirm "Make repository private?")
    
    # Create local repository
    if [ ! -d ".git" ]; then
        git init
        git checkout -b main
        print_success "Initialized local Git repository with main branch"
    else
        print_warning "Git repository already exists"
        # Ensure we're on main branch
        git checkout main 2>/dev/null || git checkout -b main
    fi
    
    # Create GitHub repository if CLI is available
    if check_gh_cli; then
        local full_repo_name="$GITHUB_USERNAME/$PARENT_REPO_NAME"
        if ! gh repo view "$full_repo_name" &> /dev/null; then
            create_github_repo "$full_repo_name" "$repo_description" "$is_private"
        else
            print_warning "Repository $full_repo_name already exists"
        fi
        
        # Set remote origin
        git remote add origin "https://github.com/$full_repo_name.git" 2>/dev/null || {
            git remote set-url origin "https://github.com/$full_repo_name.git"
        }
        print_success "Set remote origin"
    else
        print_warning "Please create the repository manually at: https://github.com/new"
        echo "Repository name: $PARENT_REPO_NAME"
        echo "Description: $repo_description"
        confirm "Press Enter when repository is created and configured" || true
    fi
    
    # Create services directory
    mkdir -p "$SERVICES_DIR"
    print_success "Created services directory"
}

create_submodule_repo() {
    local submodule_name="$1"
    local submodule_path="$SERVICES_DIR/$submodule_name"
    
    print_header "Creating Submodule: $submodule_name"
    
    # Validate that required variables are set
    if [ -z "$PARENT_REPO_NAME" ] || [ -z "$GITHUB_USERNAME" ]; then
        print_error "Parent repository must be set up first. Please run option 1."
        return 1
    fi
    
    local repo_name="$PARENT_REPO_NAME-$submodule_name"
    local full_repo_name="$GITHUB_USERNAME/$repo_name"
    local description=$(prompt_input "Enter description for $submodule_name" "$submodule_name service module")
    local template_type=$(prompt_input "Enter template type (node/python/static/empty)" "empty")
    
    # Create temporary directory for submodule
    local temp_dir="/tmp/$repo_name"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Initialize submodule repository with main branch
    git init
    git checkout -b main
    
    # Create initial files based on template
    case "$template_type" in
        "node")
            create_node_template "$submodule_name"
            ;;
        "python")
            create_python_template "$submodule_name"
            ;;
        "static")
            create_static_template "$submodule_name"
            ;;
        *)
            create_empty_template "$submodule_name"
            ;;
    esac
    
    # Create GitHub repository if CLI is available
    if check_gh_cli; then
        local is_private=$(confirm "Make $submodule_name repository private?")
        create_github_repo "$full_repo_name" "$description" "$is_private"
        
        git remote add origin "https://github.com/$full_repo_name.git"
    fi
    
    # Initial commit
    git add .
    git commit -m "Initial commit for $submodule_name service"
    
    # Push to GitHub if remote exists
    if git remote get-url origin &> /dev/null; then
        git push -u origin main
        print_success "Pushed $submodule_name to GitHub"
    fi
    
    # Return to parent directory
    cd - > /dev/null
    
    # Add as submodule to parent repository
    git submodule add "https://github.com/$full_repo_name.git" "$submodule_path"
    print_success "Added $submodule_name as submodule"
    
    # Clean up
    rm -rf "$temp_dir"
}

create_node_template() {
    local name="$1"
    cat > package.json << EOF
{
  "name": "$name",
  "version": "1.0.0",
  "description": "$name service module",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "jest"
  },
  "dependencies": {},
  "devDependencies": {
    "nodemon": "^3.0.0",
    "jest": "^29.0.0"
  }
}
EOF
    
    cat > index.js << EOF
// $name Service
console.log('$name service is running...');

module.exports = {
  start: () => {
    console.log('Starting $name service');
  }
};
EOF
    
    echo "node_modules/
*.log
.env" > .gitignore
    
    create_readme "$name" "Node.js service"
}

create_python_template() {
    local name="$1"
    cat > requirements.txt << EOF
# Add your Python dependencies here
EOF
    
    cat > main.py << EOF
"""
$name Service
"""

def main():
    print(f"$name service is running...")

if __name__ == "__main__":
    main()
EOF
    
    echo "__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.venv/
.env" > .gitignore
    
    create_readme "$name" "Python service"
}

create_static_template() {
    local name="$1"
    mkdir -p src
    
    cat > src/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$name</title>
</head>
<body>
    <h1>$name Service</h1>
    <p>Welcome to the $name service.</p>
</body>
</html>
EOF
    
    echo "dist/
.cache/
node_modules/" > .gitignore
    
    create_readme "$name" "Static website"
}

create_empty_template() {
    local name="$1"
    touch .gitkeep
    create_readme "$name" "Service module"
}

create_readme() {
    local name="$1"
    local type="$2"
    
    cat > README.md << EOF
# $name

$type for the business services architecture.

## Description

This is the $name service module.

## Getting Started

\`\`\`bash
# Clone the repository
git clone https://github.com/$GITHUB_USERNAME/$PARENT_REPO_NAME-$name.git

# Navigate to the directory
cd $PARENT_REPO_NAME-$name

# Follow setup instructions below
\`\`\`

## Development

Add your development instructions here.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
EOF
}

add_new_submodule() {
    print_header "Adding New Submodule"
    
    local submodule_name=$(prompt_input "Enter submodule name")
    
    if [ -d "$SERVICES_DIR/$submodule_name" ]; then
        print_error "Submodule $submodule_name already exists"
        return 1
    fi
    
    create_submodule_repo "$submodule_name"
    
    # Commit the submodule addition
    git add .gitmodules "$SERVICES_DIR/$submodule_name"
    git commit -m "Add $submodule_name submodule"
    
    if git remote get-url origin &> /dev/null; then
        git push origin main
        print_success "Pushed submodule addition to GitHub"
    fi
}

update_submodules() {
    print_header "Updating Submodules"
    
    git submodule update --init --recursive
    git submodule foreach 'git pull origin main'
    
    print_success "All submodules updated"
}

create_project_structure() {
    print_header "Creating Project Structure"
    
    # Create root README
    cat > README.md << EOF
# $PARENT_REPO_NAME

Business services with modular architecture using Git submodules.

## Structure

\`\`\`
$PARENT_REPO_NAME/
├── services/
│   ├── website/     # Website service
│   ├── apps/        # Applications service  
│   └── ai/          # AI service
├── scripts/         # Management scripts
└── README.md
\`\`\`

## Quick Start

\`\`\`bash
# Clone with submodules
git clone --recurse-submodules https://github.com/$GITHUB_USERNAME/$PARENT_REPO_NAME.git

# Or clone and then initialize submodules
git clone https://github.com/$GITHUB_USERNAME/$PARENT_REPO_NAME.git
cd $PARENT_REPO_NAME
git submodule update --init --recursive
\`\`\`

## Managing Submodules

\`\`\`bash
# Add a new submodule
./scripts/manage-repo.sh

# Update all submodules
git submodule update --remote

# Update specific submodule
cd services/website
git pull origin main
cd ../..
git add services/website
git commit -m "Update website submodule"
\`\`\`

## Development Workflow

1. Work in individual service directories
2. Commit changes in service repositories
3. Update parent repository to point to new commits
4. Push changes to both service and parent repositories

## Services

EOF
    
    for submodule in "${DEFAULT_SUBMODULES[@]}"; do
        echo "- **$submodule**: Located in \`services/$submodule/\`" >> README.md
    done
    
    # Create scripts directory and this script
    mkdir -p scripts
    cp "$0" scripts/manage-repo.sh 2>/dev/null || {
        print_warning "Could not copy this script to scripts directory"
    }
    
    # Create .gitignore
    cat > .gitignore << EOF
# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log

# Environment files
.env
.env.local
EOF
    
    print_success "Created project structure"
}

show_menu() {
    print_header "GitHub Repository with Submodules Manager"
    
    echo "1. Setup new parent repository"
    echo "2. Add new submodule"
    echo "3. Update all submodules"
    echo "4. Create default submodules (website, apps, ai)"
    echo "5. Show repository status"
    echo "6. Exit"
    echo
}

show_status() {
    print_header "Repository Status"
    
    if [ -d ".git" ]; then
        echo "Git Status:"
        git status --short
        echo
        
        echo "Submodules:"
        if [ -f ".gitmodules" ]; then
            git submodule status
        else
            echo "No submodules found"
        fi
    else
        echo "Not a Git repository"
    fi
}

create_default_submodules() {
    print_header "Creating Default Submodules"
    
    for submodule in "${DEFAULT_SUBMODULES[@]}"; do
        if [ ! -d "$SERVICES_DIR/$submodule" ]; then
            create_submodule_repo "$submodule"
        else
            print_warning "Submodule $submodule already exists"
        fi
    done
    
    # Commit all submodule additions
    if git diff --staged --quiet; then
        print_warning "No new submodules to commit"
    else
        git commit -m "Add default submodules: ${DEFAULT_SUBMODULES[*]}"
        
        if git remote get-url origin &> /dev/null; then
            git push origin main
            print_success "Pushed all submodules to GitHub"
        fi
    fi
}

main() {
    check_git
    
    while true; do
        show_menu
        read -p "Select an option (1-6): " choice
        
        case $choice in
            1)
                setup_parent_repo
                create_project_structure
                ;;
            2)
                add_new_submodule
                ;;
            3)
                update_submodules
                ;;
            4)
                create_default_submodules
                ;;
            5)
                show_status
                ;;
            6)
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Check if script is being run directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
