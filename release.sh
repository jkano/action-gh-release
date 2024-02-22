#!/bin/bash
# actions requires a node_modules dir https://github.com/actions/toolkit/blob/master/docs/javascript-action.md#publish-a-releasesv1-action
# but its recommended not to check these in https://github.com/actions/toolkit/blob/master/docs/action-versioning.md#recommendations
# as such the following hack is how we dill with it

if [[ $# -ne 1 ]]; then
	echo "please pass a release version. i.e. $0 v1"
	exit 1
fi

# First push changes to our current branch so the current branch is updated
git push

current_branch=$(git branch --show-current)
release_branch="releases/$1"

# Check if the current_branch is not the release_branch
if [ "$current_branch" != "$release_branch" ]; then	

	echo "We are on $current_branch"

	## If we are not in the release branch, checkout (or create) it
	if ! git show-ref --quiet refs/heads/$release_branch; then
		echo "Creating branch $release_branch"
		git checkout -b $release_branch
	else
		echo "Deleting local $release_branch..."
		git branch -d $release_branch

		echo "Creating $release_branch to update it"
		git checkout -b $release_branch
	fi
fi

rm -rf node_modules

## Backup current .gitignore
mv .gitignore .gitignore_bak
## Create new one without node_modules
echo "__tests__/runner/*" >> .gitignore

#npm install --production --silent
npm install --silent
npm run build

## Replace new .gitignore with old one
mv .gitignore_bak .gitignore

## Add everything and commit
git add .
git commit -m "Version $1"
git push origin releases/$1

# Delete the remote tag
git push --delete origin $1

# Create the tag
git tag -d $1
git tag $1

# Push
git push --tags

# Now return to your working branch
git checkout $current_branch
