#!/bin/bash
# actions requires a node_modules dir https://github.com/actions/toolkit/blob/master/docs/javascript-action.md#publish-a-releasesv1-action
# but its recommended not to check these in https://github.com/actions/toolkit/blob/master/docs/action-versioning.md#recommendations
# as such the following hack is how we dill with it

if [[ $# -ne 1 ]]; then
	echo "please pass a release version. i.e. $0 v1"
	exit 1
fi

if [ `git rev-parse --verify releases/$1 2>/dev/null` ]; then
	echo ""
else
	echo "Creating branch $1"
	git checkout -b releases/$1 # If this branch already exists, omit the -b flag
fi

rm -rf node_modules
sed -i '/node_modules/d' .gitignore # Bash command that removes node_modules from .gitignore

npm run build
npm install --production

git add node_modules -f .gitignore
git add .

git commit -m "Version $1"
git push origin releases/$1

# Delete the remote tag
git push --delete origin $1

# Create the tag
git tag $1

# Push
git push --tags


