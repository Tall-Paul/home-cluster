#! /bin/sh


RUNNINGDIR=/mnt/data
ROOTDIR=$(pwd)
PODROOTDIR=$ROOTDIR/pods
PODSTOPPED=0

check_for_updates() {
    PODNAME=$2	
    RELATIVEDIR=$(realpath --relative-to=$PODROOTDIR $1)
    for i in "$1"/*;do
        if [ -d "$i" ];then
            check_for_updates "$i" $PODNAME
        elif [ -f "$i" ]; then	    
            GIT_FILE_ABSOLUTE=$i
            GIT_FILE_RELATIVE=$(realpath --relative-to=$PODROOTDIR $i)
            if cmp -s "$GIT_FILE_ABSOLUTE" "$RUNNINGDIR/$GIT_FILE_RELATIVE"; then
              printf "."
            else   
              echo $GIT_FILE_ABSOLUTE
              echo $RUNNINGDIR/$GIT_FILE_RELATIVE           
              if [ $PODSTOPPED = 0 ]; then
		echo "Stopping $PODNAME"
		kubectl delete -f $PODROOTDIR/$PODNAME/app.yaml
                PODSTOPPED=1
	      fi
	      echo "Updating $GIT_FILE_RELATIVE"
              cp -f $GIT_FILE_ABSOLUTE $RUNNINGDIR/$GIT_FILE_RELATIVE
            fi
        fi
    done
}





git fetch --all

UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")


if [ $LOCAL = $REMOTE ]; then
    echo ""
elif [ $LOCAL = $BASE ]; then
    git pull  
fi

for f in $PODROOTDIR/*; do
    if [ -d "$f" ]; then
        PODSTOPPED=0
        check_for_updates $f $(realpath --relative-to=$PODROOTDIR $f)
        echo
        if [ $PODSTOPPED = 1 ]; then
	   echo "Restarting $(realpath --relative-to=$PODROOTDIR $f)"
	   kubectl apply -f $f/app.yaml
	else
	  echo "$(realpath --relative-to=$PODROOTDIR $f) Up to Date"
        fi
    fi
done
