# Clipd Privacy Policy

**Effective date:** 17 November 2026

Clipd is a clipboard history app for macOS. It is an open-source project
published by Folade. Questions or concerns about this policy go to
[GitHub Issues](https://github.com/net-folade/clipd/issues). Issues are
public, so don't include copied text or other personal information.

## The short version

Clipd stores your clipboard history only on your Mac and sends nothing off
it. It has no networking
code, no analytics, no crash reporting, no ads, and no third-party SDKs. The
source code is public, so you can check this yourself.

## What Clipd stores on your Mac

**Clipboard history.** Clipd checks the clipboard about every half second and
saves text you copy to a single file:

`~/Library/Containers/com.folade.clipd/Data/Library/Application Support/Clipd/history.json`

That file sits inside the app's sandbox container, and its permissions
(`0600`) stop other user accounts on this Mac from reading it. Other apps
running under your own account may still be able to read it. For each item
it stores the text, a random identifier, the time it was last copied, and
whether you pinned it. Unpinned items are capped at the history size you
choose in settings (10 to 200, default 30); the oldest are dropped first.
Pinned items don't count toward the cap and stay until you unpin or clear
them.

**Settings.** Your choices are kept in the app's standard macOS preferences,
in the same container: theme, history size, whether the Dock icon shows,
whether the keyboard shortcut is on, and the bundle identifiers (such as
`com.example.app`) of any apps you've told Clipd to ignore. macOS may also
save Clipd's window size and position there. Pause Recording is not saved.
Launch at Login is managed by macOS, not stored by Clipd; turn it off in
Clipd or in System Settings > General > Login Items before uninstalling.

To decide whether to skip a copy, Clipd looks at which app is in front. It
uses that only for the check and doesn't store it.

## What Clipd does not record

- **Anything but text.** Clipd stores only the plain-text version of a copy.
  Images and file contents are not stored, but when a copy also includes text
  (for example, the names of files copied in Finder), that text is saved.
  Copies that are empty or only whitespace are skipped.
- **Copies marked private by the app that made them.** Clipd never records a
  copy marked concealed, transient, or auto-generated under the
  [nspasteboard.org](http://nspasteboard.org) convention. Many password
  managers add these marks, but not all do. If yours doesn't, add it to
  Ignored Apps or pause recording before copying a password.
- **Copies made while recording is paused.** Pause lasts only until Clipd
  quits. When Clipd next starts, including at login, it records again.
- **Copies made while an ignored app is in front.** One limitation: macOS
  doesn't tell Clipd which app made a copy, so Clipd checks which app is in
  front when it notices the copy, up to about half a second later. If you
  copy something and switch apps within that window, Clipd may record a copy
  from an ignored app or skip one from another app. Clipd also can't tell
  when a copy comes from a menu-bar app, a background process, or another
  device, so those copies are judged by whichever app is in front. Only apps
  that show in the Dock can be added to Ignored Apps. Use Pause Recording
  when that matters.

## Permissions

Clipd runs in the macOS App Sandbox and asks for no special permissions: no
Accessibility, no Full Disk Access, and no network access. It reads the
clipboard only to save history as described above.

## Security

The history file is not encrypted. Turn on FileVault to encrypt your whole
disk. Backups such as Time Machine or cloud backup services can keep copies
of the history file, so copied text may survive in a backup after Clipd has
removed it.

## Deleting your data

- **In the app:** use the trash button. **Clear Unpinned** removes everything
  except pinned items; **Clear All** removes every item, pinned ones
  included. Clipd can't delete a single item. The file is updated about a
  second after you clear, or when Clipd quits normally.
- **By hand:** quit Clipd, then delete `history.json`. If Clipd is still
  running, it writes the history it holds in memory back to the file.
- **Uninstall:** quit Clipd and delete the app, then delete
  `~/Library/Containers/com.folade.clipd` to remove the history and settings.
  Deleting the app alone leaves that folder behind. If you used Clipd 1.0.x,
  also check for `~/Library/Application Support/Clipd` and
  `~/Library/Preferences/com.folade.clipd.plist`. They are normally moved
  into the container the first time a sandboxed version runs, but may
  remain.

## The Privacy Policy menu item

Choosing **Privacy Policy…** in Clipd's settings menu opens this page in your
default web browser. That is the only time Clipd causes anything to be
fetched from the internet, and your browser does the fetching, not Clipd.
GitHub's own privacy policy applies to that visit.

## Children's privacy

Clipd collects no personal data from anyone, children included.

## Changes to this policy

Changes are published in the Clipd repository on GitHub, in
[this file](https://github.com/net-folade/clipd/blob/main/PRIVACY.md), along
with an updated effective date. The file's history shows each earlier
version.
