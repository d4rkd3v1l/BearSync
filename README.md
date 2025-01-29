# BearSync

BearSync App was created to synchronize [Bear App](https://bear.app) notes between different accounts via git "backend".
This is by no means meant to replace the iCloud sync natively provided by Bear App and I highly recommend going for the Pro version if you need just that.
But if you get in a situation like me and need to sync some notes between different accounts, you may give it a try.

## Caution

This is a very early version, more or less really just an MVP and heavy WIP (at least when I find some time...).

⚠️⚠️⚠️ Use at your own risk. Make a backup first. Notes may get lost. ⚠️⚠️⚠️

## Usage

- Just build and run
- The App will sit in the menu bar, where you should provide some information in `Preferences` first
- Then just `Synchronize` to trigger a sync. Currently no synchronization will be triggered automatically.

## How it works

We just put all relevant notes (matched by tags) in a git repo and use this to update the notes in our local bear app installation on different/multiple Macs.

1. Find notes in local bear app installation, matching provided tags
2. Export those notes to markdown files
3. Remove note markdown files that were deleted in local bear app installation
4. Commit local changes
5. Fetch and merge (pull) remote changes from git repo
6. Update those changes to notes in local bear app installation
7. Remove remotely deleted notes from local bear app installation
8. Commit local changes (if there were any)
9. Pushing changes (if there were any)

But maybe you just want to take a look at [`Synchronizer.synchronize()`](https://github.com/d4rkd3v1l/BearSync/blob/main/BearSync/Synchronizer.swift#L62) method and follow the flow there.

We also keep a mapping to be able to map identical notes from different bear app installations, as those will have different identifiers inside bear app.

## TODO

- [x] Get rid of flickering and focus change during sync (caused by Bear x-callback-url search API, which automatically show results in Bear -.-) -> Potential fix: Pull notes directly from SQLite DB.
- [ ] Add initial git clone (for "sync repo")
- [ ] Handle merge conflicts, at least send a notification
- [ ] Image support (may never come, as it is not really important for me^^)

