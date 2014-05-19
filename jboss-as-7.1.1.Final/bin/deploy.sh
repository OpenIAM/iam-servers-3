#!/bin/bash
contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}


DD="$JBOSS_HOME/standalone/deployments"
ORDER_FILE="deploy_order"

echo $DD
echo "[MDC] Manual deployment control"
echo "[MDC] -------------------------"
echo "[MDC] Removing markers"
rm -f $DD/*.dodeploy $DD/*.isdeploying $DD/*.deployed $DD/*.failed $DD/*.undeployed $DD/*.pending $DD/*.isundeploying

APPS_ALL=( $( ls -1 $DD | grep '.ear$\|.jar$\|.war$\|.sar$' ) )

APPS_ORDER=( $( cat $ORDER_FILE ) )

echo "[MDC] ${#APPS_ALL[@]} apps in $DD: ${APPS_ALL[@]}"
echo "[MDC] Order defined for ${#APPS_ORDER[@]} apps: ${APPS_ORDER[@]}"

for APP in "${APPS_ALL[@]}"
do
    if [ $(contains "${APPS_ORDER[@]}" $APP) == "n" ]; then
        APPS_ORDER=("${APPS_ORDER[@]}" "$APP")
    fi
done

echo "[MDC] Final order of ${#APPS_ORDER[@]} apps: ${APPS_ORDER[@]}"



for APP in "${APPS_ORDER[@]}"
do
    if [ -f $DD/$APP ]; then
        echo "[MDC] File exist: $APP"
        echo "[MDC] Scheduled for deploy: $APP"
        touch "$DD/$APP.dodeploy"
        while [ ! -f "$DD/$APP.deployed" -a ! -f "$DD/$APP.failed" ]; do
            sleep 1
        done
        RESULT=`ls -1 $DD | egrep "$APP.failed|$APP.deployed"`
        echo "[MDC] Finished deploying $APP, result: $RESULT"
    else
        echo "[MDC] File not found: $APP"
    fi
done
