# AUR packaging

Two PKGBUILDs are scaffolded here for publishing to the [Arch User
Repository](https://aur.archlinux.org/):

| Package | Source | Use when |
|---|---|---|
| `niri-screensaver` | Latest release tarball (currently `v0.5.3`) | You want stable releases pinned to tagged versions |
| `niri-screensaver-git` | `main` branch, HEAD | You want bleeding-edge or to test pre-release fixes |

They `provides`/`conflicts` each other so users can only have one
installed at a time.

## Local test build

From the repo root:

```bash
cd packaging/aur/niri-screensaver
makepkg -si      # build + install for testing
makepkg --printsrcinfo > .SRCINFO   # regenerate before each AUR push
```

For the git variant the same commands apply under
`packaging/aur/niri-screensaver-git/`.

## Publishing to AUR (first time)

AUR auto-creates the empty git repo on first clone. AUR only accepts
pushes to `master`, so override modern git's `main` default during the
clone:

```bash
# Stable package
git -c init.defaultBranch=master clone \
    ssh://aur@aur.archlinux.org/niri-screensaver.git /tmp/aur-stable
cp packaging/aur/niri-screensaver/{PKGBUILD,niri-screensaver.install,LICENSE} \
   /tmp/aur-stable/
cd /tmp/aur-stable
cat > .gitignore <<'EOF'
# Whitelist: ignore everything by default; opt files in explicitly.
# Per the AUR wiki recommendation — anything new in the dir is
# ignored unless added here, so makepkg artifacts can never sneak in.
*
!.gitignore
!PKGBUILD
!.SRCINFO
!*.install
!LICENSE
!*.patch
EOF
makepkg --printsrcinfo > .SRCINFO
git add .gitignore LICENSE PKGBUILD .SRCINFO niri-screensaver.install
git commit -m "init: niri-screensaver 0.5.3-1"
git push
```

Repeat for `niri-screensaver-git` with its own AUR repo path (the
install file is `niri-screensaver-git.install` and the same
`LICENSE` ships):

```bash
git -c init.defaultBranch=master clone \
    ssh://aur@aur.archlinux.org/niri-screensaver-git.git /tmp/aur-git
cp packaging/aur/niri-screensaver-git/{PKGBUILD,niri-screensaver-git.install,LICENSE} \
   /tmp/aur-git/
cd /tmp/aur-git
# (same .gitignore as above)
makepkg --printsrcinfo > .SRCINFO
git add .gitignore LICENSE PKGBUILD .SRCINFO niri-screensaver-git.install
git commit -m "init: niri-screensaver-git"
git push
```

### Why the `.gitignore`

The AUR repo must contain **only** packaging sources — `PKGBUILD`,
`.SRCINFO`, the `.install` hook, `LICENSE`, and any local patches.
It must **not** contain build artifacts (`pkg/`, `src/`,
`*.pkg.tar.zst`) or fetched upstream tarballs. `makepkg` creates all
of those during a local test build and they'll otherwise be staged
on the next `git add -A`. From the wiki: *"The AUR should not
contain the binary tarball created by makepkg, nor should it contain
the filelist."*

The pattern above is a **whitelist** (per the wiki recommendation):
ignore everything, then explicitly re-include the small set of files
that belong in the AUR repo. If a future change adds a new file type
(say, `niri-screensaver.sig` for a signed source release), it won't
land in the AUR repo until you add a matching `!` line — fail-closed
beats fail-open here.

### Why the `LICENSE` file

Per the AUR submission guidelines: *"Add a `LICENSE` file and/or a
REUSE.toml file to your repository."* This licenses the **packaging
files themselves** (PKGBUILD, .install), separate from the upstream
software's license. 0BSD is the recommended license — *"Packages
missing a license or containing a different license than 0BSD are
not eligible for promotion to the official repositories."*

## Maintenance per release

Each time a new tag is cut here:

1. Bump `pkgver` in `packaging/aur/niri-screensaver/PKGBUILD`
2. Refresh the `sha256sums` via `updpkgsums` (or manually:
   `curl -sL https://github.com/jfreed-dev/niri-screensaver/archive/refs/tags/vX.Y.Z.tar.gz | sha256sum`)
3. Regenerate `.SRCINFO` in this repo's PKGBUILD dir
4. Sync both files into the AUR repo checkout, commit, push:
   ```bash
   cp packaging/aur/niri-screensaver/{PKGBUILD,.SRCINFO} /path/to/aur-stable/
   cd /path/to/aur-stable
   git commit -am "v0.5.x release"
   git push
   ```

The `-git` package only needs a push when the PKGBUILD itself changes —
its `pkgver()` recomputes from `git describe` at build time, so users
running `yay -Syu` automatically pick up new commits.

## Dependency notes

All declared deps exist in either the official Arch repos or AUR
(verified 2026-05-18):

| Dep | Source | Notes |
|---|---|---|
| `bash`, `alacritty`, `niri`, `jq` | extra/community | Required |
| `python-terminaltexteffects` | extra | The `tte` CLI |
| `noctalia-shell` | AUR | Optional — only for idle/lock integration |
| `playerctl` | extra | Optional — now-playing overlay |
| `wlrctl` | AUR | Optional — cursor parking |
| `ydotool` | extra | Optional — cursor parking fallback |
| `figlet` | extra | Optional — large clock/now-playing |

If `niri` itself is later moved between repos, update `depends`
accordingly.
