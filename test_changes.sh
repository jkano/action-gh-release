#!/bin/bash
# actions requires a node_modules dir https://github.com/actions/toolkit/blob/master/docs/javascript-action.md#publish-a-releasesv1-action
# but its recommended not to check these in https://github.com/actions/toolkit/blob/master/docs/action-versioning.md#recommendations
# as such the following hack is how we dill with it

current_branch="fix"
fix_branch="fixes/v0.1"
tag="v0.1"

git checkout -b $current_branch

# First push changes to our current branch so the current branch is updated
echo " - Pushing current changes to $current_branch"
git add .
git commit -m "Updating $current_branch preparing for $fix_branch" --quiet
git push --set-upstream origin $current_branch --quiet

# Check if the current_branch is not the fix_branch
if [ "$current_branch" != "$fix_branch" ]; then	

	## If we are not in the release branch, checkout (or create) it
	if ! git show-ref --quiet refs/heads/$fix_branch; then
		echo " - Creating branch $fix_branch"
		git checkout -b $fix_branch --quiet
	else
		echo " - Deleting local $fix_branch"
		git branch -D $fix_branch --quiet

		echo " - Deleting remote branch $fix_branch"
		git push origin -d $fix_branch --quiet

		echo " - Creating $fix_branch again to update it"
		git checkout -b $fix_branch --quiet
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
git commit -m "Version $tag" --quiet
git push origin $fix_branch --quiet

# Delete the remote tag
echo ""
echo " - Removing remote tag $tag (if any)"
git push --delete origin $tag --quiet

# Create the tag and push it
echo " - Creating new tag $tag"
git tag -d $tag
git tag $tag
git push --tags --quiet

# Now return to your working branch
echo ""
echo " - Switching back to $current_branch"
git checkout $current_branch --quiet

echo " ✅ Done"
