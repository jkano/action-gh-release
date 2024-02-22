#!/bin/bash
# actions requires a node_modules dir https://github.com/actions/toolkit/blob/master/docs/javascript-action.md#publish-a-releasesv1-action
# but its recommended not to check these in https://github.com/actions/toolkit/blob/master/docs/action-versioning.md#recommendations
# as such the following hack is how we dill with it

if [[ $# -ne 1 ]]; then
	echo "please pass a release version. i.e. $0 v1"
	exit 1
fi

current_branch=$(git branch --show-current)
release_branch="releases/$1"

# First push changes to our current branch so the current branch is updated
echo " - Pushing current changes to $current_branch"
git add .
git commit -m "Updating $current_branch preparing for $release_branch" --quiet
git push --quiet

# Check if the current_branch is not the release_branch
if [ "$current_branch" != "$release_branch" ]; then	

	## If we are not in the release branch, checkout (or create) it
	if ! git show-ref --quiet refs/heads/$release_branch; then
		echo " - Creating branch $release_branch"
		git checkout -b $release_branch --quiet
	else
		echo " - Deleting local $release_branch"
		git branch -D $release_branch --quiet

		echo " - Deleting remote branch $release_branch"
		git push origin -d $release_branch --quiet

		echo " - Creating $release_branch again to update it"
		git checkout -b $release_branch --quiet
	fi
fi

echo " - Removing old files to recreate"
rm -rf node_modules

## Backup current .gitignore
mv .gitignore .gitignore_bak
## Create new one without node_modules
echo "__tests__/runner/*" >> .gitignore

echo " - Installing modules ..."
npm install --silent
npm run build

## Replace new .gitignore with old one
mv .gitignore_bak .gitignore

## Add everything and commit
echo ""
echo " - Commiting new files ..."
git add .
git commit -m "Version $1" --quiet
git push origin releases/$1 --quiet

# Delete the remote tag
echo ""
echo " - Removing remote tag $1 (if any)"
git push --delete origin $1 --quiet

# Create the tag and push it
echo " - Creating new tag $1"
git tag -d $1
git tag $1
git push --tags --quiet

# Now return to your working branch
echo " - Switching back to $current_branch"
git checkout $current_branch --quiet

echo " ✅ Done"
