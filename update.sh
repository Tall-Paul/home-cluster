#! /bin/sh


RUNNINGROOTDIR=/mnt/data
ROOTDIR=$(pwd)
PODROOTDIR=$ROOTDIR/pods
UPDATEREQUIRED=0

check_for_updates() {
    PODNAME=$2	
    RELATIVEDIR=$(realpath --relative-to=$PODROOTDIR $1)
    for i in "$1"/*;do
        if [ -d "$i" ];then
            check_for_updates "$i" $PODNAME
        elif [ -f "$i" ]; then	    
            GIT_FILE_ABSOLUTE=$i
            GIT_FILE_RELATIVE=$(realpath --relative-to=$PODROOTDIR $i)

            RUNNINGFILE=$RUNNINGROOTDIR/$GIT_FILE_RELATIVE
            RUNNINGDIR=$RUNNINGROOTDIR/$RELATIVEDIR

            mkdir -p $RUNNINGDIR
	    if [ ! -f $RUNNINGFILE ]; then
              touch $RUNNINGFILE
            fi	    
            if cmp -s "$GIT_FILE_ABSOLUTE" "$RUNNINGFILE"; then
              printf "."
            else   
              echo $GIT_FILE_ABSOLUTE
              echo $RUNNINGDIR/$GIT_FILE_RELATIVE           
              if [ $UPDATEREQUIRED = 0 ]; then
                UPDATEREQUIRED=1
              fi
	          echo "Updating $GIT_FILE_RELATIVE"
              cp -f $GIT_FILE_ABSOLUTE $RUNNINGFILE
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
        PODNAME=$(realpath --relative-to=$PODROOTDIR $f)
        UPDATEREQUIRED=0
        cp -f $RUNNINGDIR/app.yaml $RUNNINGDIR/app-bak.yaml
        check_for_updates $f $PODNAME
        echo
        if [ $UPDATEREQUIRED = 1 ]; then
          if [ -f $f/secrets.yaml ]; then
            kubectl delete -f $f/secrets.yaml            
          fi
          kubectl rollout restart deployment/$PODNAME
          if [ $? != 0 ]; then   
             kubectl delete -f $RUNNINGDIR/app-bak.yaml   
             kubectl apply -f $RUNNINGDIR/app.yaml
             kubectl apply -f $f/secrets.yaml      
          fi
	    else
	        echo "$PODNAME Up to Date"
        fi
    fi
done
