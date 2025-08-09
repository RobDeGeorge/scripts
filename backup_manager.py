#!/usr/bin/env python3

import os
import shutil
import datetime
import json
import glob
from pathlib import Path


class BackupManager:
    """Centralized backup management for config files"""
    
    def __init__(self, backup_base_dir=None):
        """Initialize backup manager with base directory"""
        if backup_base_dir is None:
            # Default to backups folder in the script directory
            script_dir = os.path.dirname(os.path.abspath(__file__))
            backup_base_dir = os.path.join(script_dir, 'backups')
        
        self.backup_base_dir = Path(backup_base_dir)
        self.backup_base_dir.mkdir(exist_ok=True)
        
        # Create subdirectories for different types of backups
        self.wallpaper_backups_dir = self.backup_base_dir / 'wallpaper-changes'
        self.manual_backups_dir = self.backup_base_dir / 'manual'
        self.restore_backups_dir = self.backup_base_dir / 'restore-points'
        
        for backup_dir in [self.wallpaper_backups_dir, self.manual_backups_dir, self.restore_backups_dir]:
            backup_dir.mkdir(exist_ok=True)
    
    def create_timestamp(self):
        """Create a timestamp string for backup naming"""
        return datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    
    def backup_config_file(self, config_path, backup_type='wallpaper-changes', description=None):
        """
        Backup a single config file
        
        Args:
            config_path: Path to the config file to backup
            backup_type: Type of backup ('wallpaper-changes', 'manual', 'restore-points')
            description: Optional description for the backup
        
        Returns:
            Path to the created backup file, or None if backup failed
        """
        config_path = Path(config_path)
        
        if not config_path.exists():
            print(f"Warning: Config file not found: {config_path}")
            return None
        
        # Determine backup directory
        if backup_type == 'wallpaper-changes':
            backup_dir = self.wallpaper_backups_dir
        elif backup_type == 'manual':
            backup_dir = self.manual_backups_dir
        elif backup_type == 'restore-points':
            backup_dir = self.restore_backups_dir
        else:
            backup_dir = self.backup_base_dir / backup_type
            backup_dir.mkdir(exist_ok=True)
        
        # Create timestamped backup filename
        timestamp = self.create_timestamp()
        config_name = config_path.name
        backup_filename = f"{timestamp}_{config_name}"
        backup_path = backup_dir / backup_filename
        
        try:
            # Copy the file
            shutil.copy2(config_path, backup_path)
            
            # Create metadata file
            metadata = {
                'original_path': str(config_path),
                'backup_time': timestamp,
                'backup_type': backup_type,
                'description': description or f"Backup of {config_name}",
                'file_size': backup_path.stat().st_size
            }
            
            metadata_path = backup_dir / f"{timestamp}_{config_name}.meta.json"
            with open(metadata_path, 'w') as f:
                json.dump(metadata, f, indent=2)
            
            print(f"Backed up {config_path} to {backup_path}")
            return backup_path
            
        except Exception as e:
            print(f"Error backing up {config_path}: {e}")
            return None
    
    def backup_multiple_configs(self, config_paths, backup_type='wallpaper-changes', description=None):
        """
        Backup multiple config files as a set
        
        Args:
            config_paths: Dict of config names to paths, or list of paths
            backup_type: Type of backup
            description: Description for this backup set
        
        Returns:
            List of backup paths created
        """
        backup_paths = []
        timestamp = self.create_timestamp()
        
        if isinstance(config_paths, dict):
            paths_to_backup = config_paths.items()
        else:
            paths_to_backup = [(Path(p).name, p) for p in config_paths]
        
        # Create a set description
        set_description = description or f"Backup set created at {timestamp}"
        
        for config_name, config_path in paths_to_backup:
            backup_path = self.backup_config_file(
                config_path, 
                backup_type, 
                f"{set_description} - {config_name}"
            )
            if backup_path:
                backup_paths.append(backup_path)
        
        # Create a backup set metadata file
        if backup_paths:
            backup_dir = getattr(self, f"{backup_type.replace('-', '_')}_dir")
            set_metadata = {
                'backup_set_time': timestamp,
                'backup_type': backup_type,
                'description': set_description,
                'files_in_set': [str(bp) for bp in backup_paths],
                'original_files': dict(paths_to_backup)
            }
            
            set_metadata_path = backup_dir / f"{timestamp}_backup_set.meta.json"
            with open(set_metadata_path, 'w') as f:
                json.dump(set_metadata, f, indent=2)
        
        return backup_paths
    
    def restore_config_file(self, backup_path, target_path=None):
        """
        Restore a config file from backup
        
        Args:
            backup_path: Path to the backup file
            target_path: Where to restore (if None, uses original path from metadata)
        
        Returns:
            True if successful, False otherwise
        """
        backup_path = Path(backup_path)
        
        if not backup_path.exists():
            print(f"Error: Backup file not found: {backup_path}")
            return False
        
        # Try to load metadata to get original path
        metadata_path = backup_path.with_suffix(backup_path.suffix + '.meta.json')
        if metadata_path.exists():
            try:
                with open(metadata_path, 'r') as f:
                    metadata = json.load(f)
                original_path = metadata.get('original_path')
            except Exception as e:
                print(f"Warning: Could not read metadata: {e}")
                original_path = None
        else:
            original_path = None
        
        # Determine target path
        if target_path:
            target = Path(target_path)
        elif original_path:
            target = Path(original_path)
        else:
            print("Error: No target path specified and no metadata available")
            return False
        
        try:
            # Create target directory if needed
            target.parent.mkdir(parents=True, exist_ok=True)
            
            # Copy the backup to target location
            shutil.copy2(backup_path, target)
            print(f"Restored {backup_path} to {target}")
            return True
            
        except Exception as e:
            print(f"Error restoring {backup_path}: {e}")
            return False
    
    def list_backups(self, backup_type=None, config_name=None):
        """
        List available backups
        
        Args:
            backup_type: Filter by backup type (optional)
            config_name: Filter by config file name (optional)
        
        Returns:
            List of backup information dictionaries
        """
        backups = []
        
        # Determine which directories to search
        if backup_type:
            if backup_type == 'wallpaper-changes':
                search_dirs = [self.wallpaper_backups_dir]
            elif backup_type == 'manual':
                search_dirs = [self.manual_backups_dir]
            elif backup_type == 'restore-points':
                search_dirs = [self.restore_backups_dir]
            else:
                search_dirs = [self.backup_base_dir / backup_type]
        else:
            search_dirs = [self.wallpaper_backups_dir, self.manual_backups_dir, self.restore_backups_dir]
        
        for search_dir in search_dirs:
            if not search_dir.exists():
                continue
            
            # Find all metadata files
            for metadata_file in search_dir.glob('*.meta.json'):
                try:
                    with open(metadata_file, 'r') as f:
                        metadata = json.load(f)
                    
                    # Filter by config name if specified
                    if config_name:
                        backup_filename = metadata_file.stem.replace('.meta', '')
                        if config_name not in backup_filename:
                            continue
                    
                    # Add backup file path
                    backup_file = metadata_file.with_suffix('')
                    if backup_file.suffix == '.meta':
                        backup_file = backup_file.with_suffix('')
                    
                    metadata['backup_file'] = str(backup_file)
                    metadata['metadata_file'] = str(metadata_file)
                    backups.append(metadata)
                    
                except Exception as e:
                    print(f"Warning: Could not read metadata from {metadata_file}: {e}")
        
        # Sort by backup time (newest first)
        backups.sort(key=lambda x: x.get('backup_time', ''), reverse=True)
        return backups
    
    def cleanup_old_backups(self, backup_type='wallpaper-changes', keep_count=10):
        """
        Clean up old backups, keeping only the most recent ones
        
        Args:
            backup_type: Type of backups to clean
            keep_count: Number of recent backups to keep
        
        Returns:
            Number of backups removed
        """
        backups = self.list_backups(backup_type)
        
        if len(backups) <= keep_count:
            print(f"Only {len(backups)} backups found, no cleanup needed")
            return 0
        
        backups_to_remove = backups[keep_count:]
        removed_count = 0
        
        for backup_info in backups_to_remove:
            try:
                # Remove backup file
                backup_file = Path(backup_info['backup_file'])
                if backup_file.exists():
                    backup_file.unlink()
                
                # Remove metadata file
                metadata_file = Path(backup_info['metadata_file'])
                if metadata_file.exists():
                    metadata_file.unlink()
                
                removed_count += 1
                print(f"Removed old backup: {backup_file.name}")
                
            except Exception as e:
                print(f"Error removing backup {backup_info.get('backup_file', 'unknown')}: {e}")
        
        return removed_count
    
    def get_latest_backup(self, config_name, backup_type='wallpaper-changes'):
        """Get the most recent backup for a specific config file"""
        backups = self.list_backups(backup_type, config_name)
        return backups[0] if backups else None
    
    def create_restore_point(self, config_paths, description=None):
        """Create a restore point before making significant changes"""
        description = description or f"Restore point created at {self.create_timestamp()}"
        return self.backup_multiple_configs(config_paths, 'restore-points', description)


def main():
    """Command line interface for backup management"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Manage config file backups')
    parser.add_argument('command', choices=['backup', 'restore', 'list', 'cleanup'], 
                       help='Command to execute')
    parser.add_argument('--file', '-f', help='Config file path')
    parser.add_argument('--backup-file', '-b', help='Backup file to restore')
    parser.add_argument('--type', '-t', default='manual', 
                       choices=['wallpaper-changes', 'manual', 'restore-points'],
                       help='Backup type')
    parser.add_argument('--description', '-d', help='Backup description')
    parser.add_argument('--keep', type=int, default=10, help='Number of backups to keep during cleanup')
    
    args = parser.parse_args()
    
    backup_manager = BackupManager()
    
    if args.command == 'backup':
        if not args.file:
            print("Error: --file required for backup command")
            return 1
        
        backup_path = backup_manager.backup_config_file(args.file, args.type, args.description)
        if backup_path:
            print(f"Backup created: {backup_path}")
        else:
            print("Backup failed")
            return 1
    
    elif args.command == 'restore':
        if not args.backup_file:
            print("Error: --backup-file required for restore command")
            return 1
        
        success = backup_manager.restore_config_file(args.backup_file, args.file)
        if not success:
            return 1
    
    elif args.command == 'list':
        backups = backup_manager.list_backups(args.type)
        if not backups:
            print("No backups found")
        else:
            print(f"Found {len(backups)} backups:")
            for backup in backups:
                print(f"  {backup['backup_time']} - {backup['description']} ({backup['backup_file']})")
    
    elif args.command == 'cleanup':
        removed = backup_manager.cleanup_old_backups(args.type, args.keep)
        print(f"Removed {removed} old backups")
    
    return 0


if __name__ == '__main__':
    import sys
    sys.exit(main())