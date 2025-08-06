<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Copilot Instructions for GitHub Repository with Submodules

This project uses Git submodules to manage multiple services under a single parent repository. Each service maintains its own commit history while being organized under the main business repository.

## Project Structure
- Parent repository contains multiple services as submodules
- Each submodule is an independent Git repository
- Services are organized under the `services/` directory
- Default services: website, apps, ai

## Key Principles
- Each service should maintain independent development workflows
- Use the interactive management script for adding new submodules
- Follow the established naming convention: `{parent-repo-name}-{service-name}`
- Keep services loosely coupled but organizationally connected

## Development Guidelines
- When working on a specific service, focus on that service's directory
- Update parent repository when service repositories are updated
- Use the management script for routine operations
- Maintain clear documentation in each service's README

## Script Usage
The `setup-repo.sh` script provides interactive management of the repository structure. Use it for:
- Initial setup
- Adding new submodules
- Updating existing submodules
- Viewing repository status
