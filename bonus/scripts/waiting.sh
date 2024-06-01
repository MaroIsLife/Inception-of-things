
while [ 1 ]
do
    exit=0
    for i in 0 1
    do
        podStatus=$(kubectl get pods -n gitlab -l app='webservice' -o jsonpath="{.items[$i].status.phase}")
        if [ $podStatus = "Running" ];
        then
            echo "\033[0;32mCurrent pod status is $podStatus\033[0m"
            exit=1
            break
        else 
            echo "\033[0;34mCurrent pod status is $podStatus\033[0m"
        fi
    done
    if [ $exit = 1 ];
    then
        break
    fi
    sleep 10
done