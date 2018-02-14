#!/bin/sh

LAST_TAG=`git describe --tags --abbrev=0`
COMMITS=`git log $LAST_TAG..HEAD --pretty=oneline --abbrev-commit`

if [ "$COMMITS" = "" ]; then
  echo "Release aborted: I see no work."
  exit 1
fi

grep '^\s*"lint":' package.json > /dev/null 2>&1
if [ $? -eq 0 ]; then
  npm run lint
  if [ $? -ne 0 ]; then
    echo "Release aborted: Lint failed."
    exit 1
  fi
fi

grep '^\s*"test":' package.json > /dev/null 2>&1
if [ $? -eq 0 ]; then
  npm t
  if [ $? -ne 0 ]; then
    echo "Release aborted: Tests failed."
    exit 1
  fi
fi

grep '^\s*"minify":' package.json > /dev/null 2>&1
if [ $? -eq 0 ]; then
  npm run minify
  if [ $? -ne 0 ]; then
    echo "Release aborted: Minification failed."
    exit 1
  fi
fi

while read -r COMMIT; do
  HASH=`echo "$COMMIT" | cut -d ' ' -f 1`
  MESSAGE=`echo "$COMMIT" | cut -d ':' -f 2- | awk '{$1=$1};1'`
  TYPE=`echo "$COMMIT" | cut -d ' ' -f 2 | awk '{$1=$1};1' | cut -d ':' -f 1 | cut -d '(' -f 1 | awk '{$1=$1};1'`
  AREA=`echo "$COMMIT" | cut -d '(' -f 2 | cut -d ')' -f 1 | awk '{$1=$1};1'`

  if [ "$AREA" = "$COMMIT" ]; then
    AREA=""
  fi

  if [ "$AREA" != "" ]; then
    AREA="$AREA: "
  fi

  case $TYPE in
    "break"|"breaking")
      BUILD_TYPE="Major"
      if [ "$BREAK_SUMMARY" = "" ]; then
        BREAK_SUMMARY="### Breaking changes\n"
      fi
      BREAK_SUMMARY="$BREAK_SUMMARY\n* $AREA$MESSAGE ($HASH)"
      ;;
    "feat"|"feature")
      if [ "$BUILD_TYPE" != "Major" ]; then
        BUILD_TYPE="Minor"
      fi
      if [ "$FEAT_SUMMARY" = "" ]; then
        FEAT_SUMMARY="### New features\n"
      fi
      FEAT_SUMMARY="$FEAT_SUMMARY\n* $AREA$MESSAGE ($HASH)"
      ;;
    "fix")
      if [ "$FIX_SUMMARY" = "" ]; then
        FIX_SUMMARY="### Bug fixes\n"
      fi
      FIX_SUMMARY="$FIX_SUMMARY\n* $AREA$MESSAGE ($HASH)"
      ;;
    "perf"|"performance")
      if [ "$PERF_SUMMARY" = "" ]; then
        PERF_SUMMARY="### Performance improvements\n"
      fi
      PERF_SUMMARY="$PERF_SUMMARY\n* $AREA$MESSAGE ($HASH)"
      ;;
    "refactor")
      if [ "$REFACTOR_SUMMARY" = "" ]; then
        REFACTOR_SUMMARY="### Refactorings\n"
      fi
      REFACTOR_SUMMARY="$REFACTOR_SUMMARY\n* $AREA$MESSAGE ($HASH)"
      ;;
    *)
      if [ "$OTHER_SUMMARY" = "" ]; then
        OTHER_SUMMARY="### Other changes\n"
      fi
      OTHER_SUMMARY="$OTHER_SUMMARY\n* $AREA$MESSAGE ($HASH)"
      ;;
  esac
done <<< "$COMMITS"

if [ "$BUILD_TYPE" != "Major" -a "$BUILD_TYPE" != "Minor" ]; then
  BUILD_TYPE="Patch"
fi

if [ "$BREAK_SUMMARY" != "" ]; then
  BREAK_SUMMARY="$BREAK_SUMMARY\n\n"
fi

if [ "$FEAT_SUMMARY" != "" ]; then
  FEAT_SUMMARY="$FEAT_SUMMARY\n\n"
fi

if [ "$FIX_SUMMARY" != "" ]; then
  FIX_SUMMARY="$FIX_SUMMARY\n\n"
fi

if [ "$PERF_SUMMARY" != "" ]; then
  PERF_SUMMARY="$PERF_SUMMARY\n\n"
fi

if [ "$REFACTOR_SUMMARY" != "" ]; then
  REFACTOR_SUMMARY="$REFACTOR_SUMMARY\n\n"
fi

if [ "$OTHER_SUMMARY" != "" ]; then
  OTHER_SUMMARY="$OTHER_SUMMARY\n\n"
fi

SUMMARY="$BREAK_SUMMARY$FEAT_SUMMARY$FIX_SUMMARY$PERF_SUMMARY$REFACTOR_SUMMARY$OTHER_SUMMARY"

MAJOR=`echo "$LAST_TAG" | cut -d '.' -f 1`
MINOR=`echo "$LAST_TAG" | cut -d '.' -f 2`
PATCH=`echo "$LAST_TAG" | cut -d '.' -f 3`

SED_FRIENDLY_LAST_TAG="$MAJOR\\.$MINOR\\.$PATCH"

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

if [ -f bower.json ]; then
  sed -i '' "s/\"version\": \"$LAST_TAG\"/\"version\": \"$NEW_TAG\"/" bower.json
fi

if [ -f component.json ]; then
  sed -i '' "s/\"version\": \"$LAST_TAG\"/\"version\": \"$NEW_TAG\"/" component.json
fi

if [ -f package.json ]; then
  sed -i '' "s/\"version\": \"$LAST_TAG\"/\"version\": \"$NEW_TAG\"/" package.json
fi

if [ -f setup.py ]; then
  sed -i '' "s/$SED_FRIENDLY_LAST_TAG/$NEW_TAG/g" setup.py
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
  awk "{ gsub(/^## $LAST_TAG$/, \"## $NEW_TAG\n\n$SUMMARY## $LAST_TAG\") }; { print }" "$LOG" > "$TEMP"
  mv "$TEMP" "$LOG"
fi

GIT_FRIENDLY_SUMMARY=`echo "$SUMMARY" | sed "s/#//g" | sed "s/^ //"`

git commit -a -m "release: $NEW_TAG"
git tag -a "$NEW_TAG" -m "`echo \"$BUILD_TYPE release $NEW_TAG\\n\\n$GIT_FRIENDLY_SUMMARY\"`"

