#!/bin/bash

# FUNÇÃO PARA CHECAR SE TAG JA EXISTE OU NÃO
function main(){

version=$(cat version.json | grep version | grep -Eo "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+")
for THIS_TAG in "$version"; do

    if [ $(git tag -l "$THIS_TAG") ]; then
        echo "Tag $THIS_TAG já existe. Adicionando alterações no CHANGELOG.md ..."
        changelog > CHANGELOG.md
        commitChangelog
    else
        echo "Tag $THIS_TAG não existe. Criando tag e adicionando notas de alterações no CHANGELOG.md ..."
        createTag
        changelog > CHANGELOG.md
        commitChangelog
    fi
done

}

# FUNÇÃO QUE GERA O CHANGELOG
function changelog(){

echo "# 🎁 Release notes"

git tag --sort=-creatordate | while read TAG ; do
    echo
    if [ $NEXT ];then
        tag_date=$(git log -1 --pretty=format:'%ad' --date=short ${TAG})
        echo "## $NEXT - ($tag_date)"
    else
        echo "## Current - Work in progress"
    fi  
    echo "### Merges"
    GIT_PAGER=cat git log ${TAG}...${NEXT} --merges --pretty=format:"*  %s [View]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/commits/%H)"
    echo 
    echo "### Commits"
    GIT_PAGER=cat git log ${TAG}...${NEXT} --pretty=format:"*  %s [View]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/commits/%H)" --reverse | grep -v Merge
    NEXT=$TAG
    printf "\n\n"
done
FIRST=$(git tag -l --sort=v:refname | head -1)
tag_date=$(git log -1 --pretty=format:'%ad' --date=short ${FIRST})
echo
echo "## $FIRST - ($tag_date)"
echo "### Merges"
GIT_PAGER=cat git log ${FIRST} --merges --pretty=format:"*  %s [View]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/commits/%H)"
echo 
echo "### Commits"
GIT_PAGER=cat git log ${FIRST} --pretty=format:"*  %s [View]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/commits/%H)" --reverse | grep -v Merge


metadata

}

# FUNÇÃO QUE COMMITA O CHANGELOG
function commitChangelog(){

git add CHANGELOG.md 
git commit -m "docs(📚 CHANGELOG): update release notes"
git push origin HEAD:main

}

# FUNÇÃO QUE GERA OS METADADOS
function metadata(){

DATE=$(git log -1 --pretty=format:'%ad' --date=short)
VERSION=$(git tag --sort=-committerdate | head -5)
PREVIOUS_VERSION=$(git tag --sort=-committerdate | head -2 | awk '{split($0, tags, "\n")} END {print tags[1]}')
CHANGES=$(git log --pretty="- %s" $VERSION...$PREVIOUS_VERSION)
# printf "# 🎁 Release notes (\`$VERSION\`)\n\n## Changes\n$CHANGES\n\n## Metadata\n\`\`\`\nThis version -------- $VERSION\nPrevious version ---- $PREVIOUS_VERSION\nTotal commits ------- $(echo "$CHANGES" | wc -l)\n\`\`\`\n" 
printf "## 📝 Metadata\n\`\`\`\nThis version -------- $VERSION\nPrevious version ---- $PREVIOUS_VERSION\nTotal commits ------- $(echo "$CHANGES" | wc -l)\n\`\`\`\n" 

}

# FUNÇÃO PARA CRIAR TAGS
function createTag(){

git tag "$THIS_TAG"
git push  --tags $GITHUB_SERVER_URL/$GITHUB_REPOSITORY.git HEAD:main

}

# CHAMANDO FUNÇÃO PRINCIPAL
main