<img align="right" src="https://visitor-badge.laobi.icu/badge?page_id=platima.docker-container-config-backup" height="20" />

# Docker Compose Export

A bash script to automatically export `docker-compose.yml` files for all your running and stopped Docker containers using [docker-autocompose](https://github.com/Red5d/docker-autocompose).

## Why This Exists

Ever needed to recreate your Docker setup after a system migration or disaster recovery? This script makes it trivial to backup your container configurations as compose files, which you can version control or use to spin up identical containers elsewhere.

## Features

- Exports all containers (running and stopped) to individual compose files
- Configurable output directory
- Colour-coded terminal output
- Error handling and validation
- Progress reporting with success/failure counts
- Automatic cleanup of failed exports

## Requirements

- Docker installed and running
- Access to `/var/run/docker.sock`
- Bash 4.0 or later
- Internet connection (to pull the docker-autocompose image)

## Installation

```bash
# Clone the repository
git clone https://github.com/platima/docker-compose-export.git
cd docker-compose-export

# Make the script executable
chmod +x docker-compose-export.sh
```

## Usage

### Basic Usage

Export all containers to the current directory (default: `{name}-{id}.compose.yml`):

```bash
./docker-compose-export.sh
```

### Specify Output Directory

Export all containers to a specific directory:

```bash
./docker-compose-export.sh -o ~/docker-backups
```

### Naming Options

Use only container names in filenames:

```bash
./docker-compose-export.sh --nameonly
```

Use only container IDs in filenames:

```bash
./docker-compose-export.sh --idonly
```

Combine options:

```bash
./docker-compose-export.sh -o ~/backups --nameonly
```

### Get Help

```bash
./docker-compose-export.sh -h
```

## Output

The script creates compose files using the naming format you specify:

**Default (both name and ID):**
```
nginx-proxy-a1b2c3d4e5f6.compose.yml
postgres-db-9f8e7d6c5b4a.compose.yml
redis-cache-1a2b3c4d5e6f.compose.yml
```

**With `--nameonly`:**
```
nginx-proxy.compose.yml
postgres-db.compose.yml
redis-cache.compose.yml
```

**With `--idonly`:**
```
a1b2c3d4e5f6.compose.yml
9f8e7d6c5b4a.compose.yml
1a2b3c4d5e6f.compose.yml
```

## Example Output

```
Pulling latest docker-autocompose image...

Found 3 container(s) to export
Output directory: /home/user/docker-backups

Exporting nginx-proxy (a1b2c3d4e5f6)...
✓ Exported: /home/user/docker-backups/nginx-proxy-a1b2c3d4e5f6.compose.yml
Exporting postgres-db (9f8e7d6c5b4a)...
✓ Exported: /home/user/docker-backups/postgres-db-9f8e7d6c5b4a.compose.yml
Exporting redis-cache (1a2b3c4d5e6f)...
✓ Exported: /home/user/docker-backups/redis-cache-1a2b3c4d5e6f.compose.yml

==========================================
Export complete!
Successful: 3
==========================================
```

## How It Works

The script:

1. Validates that Docker is running
2. Pulls the latest `docker-autocompose` image
3. Gets a list of all container IDs
4. For each container:
   - Retrieves the container name
   - Runs docker-autocompose to generate the compose file
   - Saves it with a sanitised filename
5. Reports success/failure statistics

## Limitations

- The generated compose files may need manual tweaking for your specific use case
- Some Docker features may not be perfectly represented in the exported compose files
- Network configurations might need adjustment when recreating containers

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

## License

MIT License - See LICENSE file for details

## Credits

- [docker-autocompose](https://github.com/Red5d/docker-autocompose) by Red5d - The tool that does the heavy lifting
- Script by [Platima](https://github.com/platima)

## Related Projects

- [composerize](https://github.com/magicmark/composerize) - Convert docker run commands to compose files
