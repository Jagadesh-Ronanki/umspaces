# umspaces

Business services with modular architecture using Git submodules.

## Structure

```
umspaces/
├── services/
│   ├── website/     # Website service
│   ├── apps/        # Applications service  
│   └── ai/          # AI service
├── scripts/         # Management scripts
└── README.md
```

## Quick Start

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/Jagadesh-Ronanki/umspaces.git

# Or clone and then initialize submodules
git clone https://github.com/Jagadesh-Ronanki/umspaces.git
cd umspaces
git submodule update --init --recursive
```

## Managing Submodules

```bash
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
```

## Development Workflow

1. Work in individual service directories
2. Commit changes in service repositories
3. Update parent repository to point to new commits
4. Push changes to both service and parent repositories

## Services

- **website**: Located in `services/website/`
- **apps**: Located in `services/apps/`
- **ai**: Located in `services/ai/`
