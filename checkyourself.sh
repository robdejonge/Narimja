#!/usr/local/bin/bash
#ddd

function checkForUpdates {

  FILENAME=$(basename $1)

  PREVIOUS_COMMIT=$(tail -3 $FILENAME | grep $FILENAME | grep ^#commit | awk -F'=' '{ print $2}')
  PREVIOUS_CHECK=$(tail -3 $FILENAME | grep $FILENAME | grep ^#check | awk -F'=' '{ print $2}')
  ELAPSED=$(expr $(date +%s) - $(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$PREVIOUS_CHECK" +%s))

  # check only if it has been a while
  if [ "$ELAPSED" -gt 300 ]; then

    COMMITS_JSON=$(curl -s "https://api.github.com/repos/robdejonge/Narimja/commits?path=$FILENAME&since=$PREVIOUS_COMMIT")
    COMMIT_COUNT=$(echo $COMMITS_JSON | jq  '. | length')
    LAST_COMMIT=$(echo $COMMITS_JSON | jq '.[0]["commit"]["committer"]["date"]' | tr -d '"')
    LAST_CHECK=$(date +"%Y-%m-%dT%H:%M:%SZ")

    if [ $COMMIT_COUNT -gt 1 ]; then

      # if there are new commits, download the latest and append the latest commit and check timestamps
      curl -s -o updated_$FILENAME "https://raw.githubusercontent.com/robdejonge/Narimja/master/$FILENAME"
      echo " " >>updated_$FILENAME
      echo "#-------" >>updated_$FILENAME
      echo "#commit($FILENAME)=$LAST_COMMIT" >>updated_$FILENAME
      echo "#check($FILENAME)=$LAST_CHECK" >>updated_$FILENAME


    else

      # if there are no new commits, update the latest check timestamp
      NROFLINESTOCOPY=$(expr $(wc -l $FILENAME | awk '{print $1}') - 1 )
      head -n$NROFLINESTOCOPY $FILENAME >updated_$FILENAME
      echo "#check($FILENAME)=$LAST_CHECK" >>updated_$FILENAME

    fi

    chmod +x updated_$FILENAME
    mv $FILENAME deleted_$FILENAME
    mv updated_$FILENAME $FILENAME

  fi
}
