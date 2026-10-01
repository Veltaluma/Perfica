# Perfica Backup Format

## Purpose

Perfica's backup subsystem preserves user-controlled local data across
reinstalls, device changes, and format evolution.

Backup compatibility is a data-integrity concern.

## Components

### BackupService

Handles historical JSON backup compatibility.

### DataBackupService

Application-facing import/export facade and format routing.

### PortableBackupBuilder

Creates current portable backups.

### PortableBackupRestorer

Validates and restores supported portable backups, attachments, migrations, and
post-restore normalization.

## Current portable format

The current production portable path uses a v4 manifest.

The repository also contains compatibility tests for older supported portable
behavior.

Do not change the manifest version without designing corresponding read,
migration, and test behavior.

## Historical compatibility

Legacy import formats should not be removed merely because the current writer no
longer creates them.

Removing import support is a user-data migration decision.

## Database data

Current normalized storage includes task and focus data across dedicated Drift
tables.

Backups must preserve relationships and values needed to reconstruct valid
application state.

## Attachments

Attachments are files, not only database strings.

Backup creation/restoration must preserve:

- managed attachment bytes;
- safe filenames and paths;
- task association;
- deterministic restoration behavior.

## Path safety

Archive input is untrusted.

Restore code must reject attempts to write outside managed restoration
locations.

Path-traversal protection is a security requirement.

## Atomicity

A failed restore should not leave the user with a partially replaced or silently
corrupted active dataset.

Restore changes should preserve rollback-safe or transactional behavior where the
subsystem provides it.

## Normalization

Older structures can require normalization into the current schema.

Do not delete old representation data before equivalent current data has been
created and verified.

## Schema migration vs backup migration

Database schema migration upgrades an installed database.

Backup compatibility imports serialized data.

A change can affect one, both, or neither.

Passing database migration tests alone does not prove backup compatibility.

## Required tests for backup changes

Depending on the change, tests should cover:

- current backup round trip;
- historical restore;
- unsupported extension/version handling;
- malformed input;
- attachment restoration;
- path traversal rejection;
- normalization;
- failed restore rollback;
- re-export after restoration.

## Versioning rule

When changing the portable backup schema:

1. document the new version;
2. retain supported old readers;
3. update the writer;
4. add fixtures/tests;
5. test attachments;
6. test normalization;
7. verify failed-restore safety;
8. verify re-export behavior.

Do not silently reinterpret an existing version number as a different format.
