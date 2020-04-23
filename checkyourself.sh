#!/usr/local/bin/bash

function checkForUpdates {

  PARAMETER=$(realpath $1)

  FILEPATH=$(dirname $PARAMETER)
  FILENAME=$(basename $PARAMETER)

  echo "$FILENAME: checking for $FILEPATH/$FILENAME"

  PREVIOUS_COMMIT=$(tail -3 $FILEPATH/$FILENAME | grep $FILENAME | grep ^#commit | awk -F'=' '{ print $2}')
  PREVIOUS_CHECK=$(tail -3 $FILEPATH/$FILENAME | grep $FILENAME | grep ^#check | awk -F'=' '{ print $2}')

  echo "$FILENAME: previous commit was $PREVIOUS_COMMIT"
  echo "$FILENAME: previous check was $PREVIOUS_CHECK"

  ELAPSED=$(expr $(date +%s) - $(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$PREVIOUS_CHECK" +%s))

  echo "$FILENAME: $ELAPSED seconds since last check"

  # check only if it has been a while
  if [ "$ELAPSED" -gt 30 ]; then

    echo "$FILENAME: checking for new commits"

    COMMITS_JSON=$(curl -s "https://api.github.com/repos/robdejonge/Narimja/commits?path=$FILENAME&since=$PREVIOUS_COMMIT")
    COMMIT_COUNT=$(echo $COMMITS_JSON | jq  '. | length')
    LAST_COMMIT=$(echo $COMMITS_JSON | jq '.[0]["commit"]["committer"]["date"]' | tr -d '"')
    LAST_CHECK=$(date +"%Y-%m-%dT%H:%M:%SZ")

    echo "$FILENAME: commit count $COMMIT_COUNT"

    if [ $COMMIT_COUNT -gt 1 ]; then

      echo "$FILENAME: latest commit found at $LAST_COMMIT"
      echo "$FILENAME: downloading, marking as last checked at $LAST_CHECK"

      # if there are new commits, download the latest and append the latest commit and check timestamps
      curl -s -o $FILEPATH/updated_$FILENAME "https://raw.githubusercontent.com/robdejonge/Narimja/master/$FILENAME?$(date +%s)"
      echo " " >>$FILEPATH/updated_$FILENAME
      echo "#-------" >>$FILEPATH/updated_$FILENAME
      echo "#commit($FILENAME)=$LAST_COMMIT" >>$FILEPATH/updated_$FILENAME
      echo "#check($FILENAME)=$LAST_CHECK" >>$FILEPATH/updated_$FILENAME


    else

      echo "$FILENAME: no new commit found, updating last checked to $LAST_CHECK"

      # if there are no new commits, update the latest check timestamp
      NROFLINESTOCOPY=$(expr $(wc -l $FILEPATH/$FILENAME | awk '{print $1}') - 1 )
      head -n$NROFLINESTOCOPY $FILEPATH/$FILENAME >$FILEPATH/updated_$FILENAME
      echo "#check($FILENAME)=$LAST_CHECK" >>$FILEPATH/updated_$FILENAME

    fi

    chmod +x $FILEPATH/updated_$FILENAME
    mv $FILEPATH/$FILENAME $FILEPATH/deleted_$FILENAME
    mv $FILEPATH/updated_$FILENAME $FILEPATH/$FILENAME
    rm $FILEPATH/deleted_$FILENAME

  else

    echo "$FILENAME: nothing to do"

  fi
}

checkForUpdates "${BASH_SOURCE[0]}"
