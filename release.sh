#!/bin/sh

LAST_TAG=`git describe --tags --abbrev=0`
COMMITS=`git log $LAST_TAG..HEAD --pretty=oneline --abbrev-commit`

if [ "$COMMITS" = "" ]; then
  echo "Release aborted: I see no work."
  exit 1
fi

grep '^\s*"lint":' package.json > /dev/null
if [ $? -eq 0 ]; then
  npm run lint
  if [ $? -ne 0 ]; then
    echo "Release aborted: Lint failed."
    exit 1
  fi
fi

grep '^\s*"test":' package.json > /dev/null
if [ $? -eq 0 ]; then
  npm t
  if [ $? -ne 0 ]; then
    echo "Release aborted: Tests failed."
    exit 1
  fi
fi

grep '^\s*"minify":' package.json > /dev/null
if [ $? -eq 0 ]; then
  npm run minify
  if [ $? -ne 0 ]; then
    echo "Release aborted: Minification failed."
    exit 1
  fi
fi

while read -r COMMIT; do
  HASH=`echo "$COMMIT" | cut -d ' ' -f 1`
  MESSAGE=`echo "$COMMIT" | cut -d ':' -f 2-`
  TYPE=`echo "$COMMIT" | cut -d ' ' -f 2 | cut -d ':' -f 1 | cut -d '(' -f 1`

  case $TYPE in
    "break"|"breaking")
      BUILD_TYPE="Major"
      TYPE="breaking change"
      ;;
    "feat"|"feature")
      if [ "$BUILD_TYPE" != "Major" ]; then
        BUILD_TYPE="Minor"
      fi
      TYPE="feature"
      ;;
    *)
      if [ "$BUILD_TYPE" != "Major" -a "$BUILD_TYPE" != "Minor" ]; then
        BUILD_TYPE="Patch"
      fi
  esac

  SUMMARY="* $TYPE:$MESSAGE ($HASH)\n$SUMMARY"
done <<< "$COMMITS"

MAJOR=`echo "$LAST_TAG" | cut -d '.' -f 1`
MINOR=`echo "$LAST_TAG" | cut -d '.' -f 2`
PATCH=`echo "$LAST_TAG" | cut -d '.' -f 3`

case $BUILD_TYPE in
  "Major")
    MAJOR=`expr $MAJOR + 1`
    MINOR=0
    PATCH=0
    ;;
  "Minor")
    MINOR=`expr $MINOR + 1`
    PATCH=0
    ;;
  "Patch")
    PATCH=`expr $PATCH + 1`
    ;;
esac

NEW_TAG="$MAJOR.$MINOR.$PATCH"

sed -i '' "s/\"version\": \"$LAST_TAG\"/\"version\": \"$NEW_TAG\"/" package.json

if [ -f bower.json ]; then
  sed -i '' "s/\"version\": \"$LAST_TAG\"/\"version\": \"$NEW_TAG\"/" bower.json
fi

if [ -f component.json ]; then
  sed -i '' "s/\"version\": \"$LAST_TAG\"/\"version\": \"$NEW_TAG\"/" component.json
fi

if [ -f CHANGELOG.md ]; then
  LOG="CHANGELOG.md"
elif [ -f CHANGES.md ]; then
  LOG="CHANGES.md"
elif [ -f HISTORY.md ]; then
  LOG="HISTORY.md"
elif [ -f CHANGELOG.txt ]; then
  LOG="CHANGELOG.txt"
elif [ -f CHANGES.txt ]; then
  LOG="CHANGES.txt"
elif [ -f HISTORY.txt ]; then
  LOG="HISTORY.txt"
elif [ -f CHANGELOG ]; then
  LOG="CHANGELOG"
elif [ -f CHANGES ]; then
  LOG="CHANGES"
elif [ -f HISTORY ]; then
  LOG="HISTORY"
fi

if [ "$LOG" != "" ]; then
  TEMP="__please_release_me_$LOG.$NEW_TAG.tmp"
  awk "{ gsub(/^## $LAST_TAG$/, \"## $NEW_TAG\n\n$SUMMARY\n## $LAST_TAG\") }; { print }" "$LOG" > "$TEMP"
  mv "$TEMP" "$LOG"
fi

git commit -a -m "release: $NEW_TAG"
git tag -a "$NEW_TAG" -m "`echo \"$BUILD_TYPE release\n\n$SUMMARY\"`"

