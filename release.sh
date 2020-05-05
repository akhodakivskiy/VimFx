#!/bin/sh

:<<'DOCS'
(helps to) prepare a new VimFx release. 

note: by default, my (@girst's) pretty idiosyncratic development environment is
assumed to be present (i'm pushing unstable commits to a second git-remote and
only push 'release-quality' commits to upstream). these are easily overwritten
by passing them in the calling environment. alternatively, changes to can be
temporarily ignored by git with `git update-index --assume-unchanged FILE`.

inspired by https://drewdevault.com/2019/10/12/how-to-fuck-up-releases.html
DOCS

# shadowable defaults:
: "${devel=origin/master}"
: "${release=upstream/master}"
: "${git_user=girst}"
: "${git_email=girst@users.noreply.github.com}"
: "${devel_url=https://github.com/girst/VimFx}"
: "${release_url=https://github.com/akhodakivskiy/VimFx}"

set -e
export LC_ALL=C

die() {
	echo "$@" >&2
	exit 1
}

last_version=$(awk -F\" '$2 == "version" { print $4 ; exit }' package.json)
inc_version() {
	echo "$last_version" |
	awk -F. -vOFS=. '{ $ver++; while(ver++<NF) $ver=0; print $0 }' ver="$1"
}

case "$1" in
patch)	next_version=$(inc_version 3) ;;
minor)	next_version=$(inc_version 2) ;;
major)	die "no." ;;
*)	die "Usage: $0 {minor|patch}"
esac

# make sure my idiosyncratic development setup is present
test "$(git config --show user.name | cut -f2)" = "$git_user" ||
	die "username not set to $git_user, aborting."
test "$(git config --show user.email | cut -f2)" = "$git_email" ||
	die "email not set to $git_email, aborting."
git remote show | grep -q "${devel%%/*}" ||
	die "there is no development remote, aborting."
git remote show | grep -q "${release%%/*}" ||
	die "there is no release remote, aborting."
test "$(git remote get-url "${devel%%/*}")" = "$devel_url" ||
	die "development remote not set up, aborting."
test "$(git remote get-url "${release%%/*}")" = "$release_url" ||
	die "release remote not set up, aborting."

# make sure we are on the master branch
git rev-parse --abbrev-ref HEAD | grep -q '^master$' ||
	die "not on branch master, aborting."

# make sure changes are committed. ignores untracked local files (todo-lists).
git diff-index HEAD --quiet || {
	git status --porcelain --untracked-files=no >&2
	die "uncommited changes found, aborting.";}

# make sure local repo is up to date (push to devel and pull from release first)
git remote update
git rev-list "HEAD...$devel" | grep -q . && # rebased?
	die "local out of date (v. $devel), aborting. consider git push --force-with-lease ${devel%%/*}"
git rev-list "HEAD..$release" | grep -q . && # pulled?
	die "local out of date (v. $release), aborting. consider issuing git pull --rebase ${release%%/*}"

# at this point, we should save the current HEAD, so we can restore later on
old_head=$(git rev-parse HEAD)

# lint coffee files
npm --silent run -- gulp --silent lint coffee ||
	die "linting errors detected, aborting."

# update CHANGELOG.md and ask user to confirm changes
cat <<EOF | ed -s CHANGELOG.md
1i
### $next_version (`date +%Y-%m-%d`)


.
2r !git log --reverse --format="- "\%s v$last_version..HEAD
wq
EOF
${VISUAL:-$EDITOR} CHANGELOG.md

# increment version number in package.json
sed -i "/\"version\":/s/$last_version/$next_version/" package.json

# commit and tag release
git add CHANGELOG.md package.json
git commit -m "VimFx v$next_version"
git tag "v$next_version"

# build xpi for release on github
npm --silent run -- gulp --silent xpi --unlisted

printf "continue pushing to upstream repository [y/N]: " >&2
read -r confirm
case "$confirm" in
[!yY])	git reset --hard "$old_head"
	git tag --delete "v$next_version"
	die "ok, aborting and resetting."
esac

# push commits and tags to upstream repo
git push --follow-tags ${release%%/*}

# open prepopulated release form (don't forget to upload xpi!)
tmpdir=$(mktemp -d) && cp build/VimFx.xpi "$tmpdir" && xdg-open "$tmpdir" &
firefox --new-window "https://github.com/akhodakivskiy/VimFx/releases/new?tag=v${next_version}&title=VimFx+v${next_version}&body=" &
