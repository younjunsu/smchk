#!/usr/bin/bash
####################################################
# SYSMASTER7 Maintenance Shell                     #
####################################################
 
## Default Configuration
JEUS_ID=jeus
JEUS_PSW=jeus
SMDB_ID=sys
SMDB_PSW=tibero

## Program variables
RECENT_DAYS=$1
if [ $RECENT_DAYS -z ]
then
    RECENT_DAYS=30
fi

SMDB_LOG_PATH=`cat $TB_HOME/config/$TB_SID.tip |grep "LOG_DEFAULT_DEST"`
if [ $SMDB_LOG_PATH -z ]
then
    SMDB_LOG_PATH="tibero6/instance"
fi
##

## Program function
function ft_step_env(){
STEP="1"
    printf "#%-50s#\n" "##################################################"
    printf "#%-50s#\n" " SYSMASTER7 Maintenance Result"
    printf "#%-50s#\n" " `date +%Y-%m-%d" "%T`"
    printf "#%-50s#\n" "##################################################"
    echo
    echo
    if [ $SYSMASTER_HOME -z ] || [ $TB_HOME -z ] || [ $TB_SID -z ] || [ $JEUS_HOME -z ] || [$HL_HOME -z ] || [ $PROOBJECT_HOME -z]
    then
        echo "[ERROR] Check environment variables"
        echo
        printf "%-20s%-100s\n" "Home type" "Path"
        echo "---------------------------------"
        printf "%-20s|%-100s\n" "SYSMASTER_HOME" "$SYSMASTER_HOME"
        printf "%-20s|%-100s\n" "TB_HOME" "$TB_HOME"
        printf "%-20s|%-100s\n" "TB_SID" "$TB_SID"
        printf "%-20s|%-100s\n" "JEUS_HOME" "$JEUS_HOME"
        printf "%-20s|%-100s\n" "HL_HOME" "$HL_HOME"
        printf "%-20s|%-100s\n" "PROOBJECT_HOME" "$PROOBJECT_HOME"
        echo "---------------------------------"
        exit
    fi
    echo "######## $STEP. Environment check ########"
    printf "%-20s%-100s\n" "Home type" "Path"
    echo "---------------------------------"
    printf "%-20s%-100s\n" "SYSMASTER_HOME" "$SYSMASTER_HOME"
    printf "%-20s%-100s\n" "TB_HOME" "$TB_HOME"
    printf "%-20s%-100s\n" "TB_SID" "$TB_SID"
    printf "%-20s%-100s\n" "JEUS_HOME" "$JEUS_HOME"
    printf "%-20s%-100s\n" "HL_HOME" "$HL_HOME"
    printf "%-20s%-100s\n" "PROOBJECT_HOME" "$PROOBJECT_HOME"
    echo
    echo
    echo "######## Directory Creation Time ########"
    printf "%-20s%-100s\n" "Home type" "Creation Time"
    echo "---------------------------------"
    printf "%-20s%-100s\n" "SYSMASTER_HOME" "`stat $SYSMASTER_HOME |grep Access |grep -v Gid`"
    printf "%-20s%-100s\n" "TB_HOME" "`stat $TB_HOME |grep Access |grep -v Gid`"
    printf "%-20s%-100s\n" "JEUS_HOME" "`stat $JEUS_HOME |grep Access |grep -v Gid`"
    printf "%-20s%-100s\n" "HL_HOME" "`stat $HL_HOME |grep Access |grep -v Gid`"
    printf "%-20s%-100s\n" "PROOBJECT_HOME" "`stat $PROOBJECT_HOME |grep Access |grep -v Gid`"
    echo
    echo
}

function ft_step_version(){
STEP="2"
    echo "######## $STEP. SysMaster version check ########"
    echo "######## $STEP.1. JEUS ########"
    $JEUS_HOME/bin/jeusadmin -version
    $JEUS_HOME/bin/jeusadmin -fullversion
    echo
    echo "######## $STEP.2. Sysmaster UI  ########"
    VERSION_PATH=$PROOBJECT_HOME/application/sysmaster7db/bin 
    unzip -o $VERSION_PATH/file/sysmaster_db.war META-INF/MANIFEST.MF -d $VERSION_PATH/file/version |grep -vE "Archive:|inflating:"
    cat $VERSION_PATH/file/version/META-INF/MANIFEST.MF
    echo "######## $STEP.3. Sysmaster Server  ########"
    VERSION_PATH=$PROOBJECT_HOME/application/sysmaster7db/common
    java -jar $VERSION_PATH/lib/common.jar
    echo "######## $STEP.4. SMDB ########"
    tbboot -version
    echo
}

function ft_step_system(){
STEP="3"
    echo "######## $STEP. System resource ########"
    echo "######## $STEP.1. Memory ########"
    free -g
    echo
    echo "######## $STEP.2. CPU ########"
    SYSTEM_CPU=`cat /proc/cpuinfo |grep -i "physical id" |sort |uniq -c |awk '{print $1}' |wc -l`
    SYSTEM_CORE=`cat /proc/cpuinfo |grep -i "physical id" |sort |uniq -c |awk '{sum +=$1} END {print sum}'`
    echo "CPU = "$SYSTEM_CPU", CORE ="$SYSTEM_CORE
    echo
    echo
}

function ft_step_uptime(){
STEP="4"
    echo "######## $STEP. Started time ########"
    echo "Current dateTime "`date +%Y-%m-%d" "%T`
    printf "%-20s%-50s%-20s%-30s\n" "TYPE" "Prcess CMD" "PID" "START-TIME"
    echo "-------------------------------------------------------------------------------------------------------------"
    # SYSTEMD
    SYSTEM_STARTTIME=`uptime -s`
    SYSTEM_CMD="systemd"
    printf "%-20s%-50s%-20s%-30s\n" "SYSTEM" "$SYSTEM_CMD" "1" "$SYSTEM_STARTTIME"
    
    # SMDB
    SMDB_PID=`ps -ef |grep -w tbsvr |grep -v grep |awk '{print $2}'`
    SMDB_STARTTIME=`ps -eo lstart,pid,cmd |grep $SMDB_PID|grep -vE "grep|cub_admin"| awk '{
    cmd="date -d\""$1 FS $2 FS $3 FS $4 FS $5"\" +\047%Y-%m-%d %H:%M:%S\047"; 
    cmd | getline d; close(cmd); $1=$2=$3=$4=$5=""; printf "%s\n",d$0 }' 2>/dev/null |awk '{print $1" "$2}'`
    SMDB_CMD="TIBERO"
    printf "%-20s%-50s%-20s%-30s\n" "SMDB" "$SMDB_CMD" "$SMDB_PID" "$SMDB_STARTTIME"

    # JEUS
    JEUS_PIDS=(`ps -ef|grep sysmaster |grep java |grep jeus |awk '{print $2}'`)
    for JEUS_PID in ${JEUS_PIDS[@]}
    do
        JEUS_STARTTIME=`ps -eo lstart,pid,cmd |grep $JEUS_PID|grep -vE "grep|cub_admin"| awk '{
        cmd="date -d\""$1 FS $2 FS $3 FS $4 FS $5"\" +\047%Y-%m-%d %H:%M:%S\047"; 
        cmd | getline d; close(cmd); $1=$2=$3=$4=$5=""; printf "%s\n",d$0 }' 2>/dev/null |awk '{print $1" "$2}'`
        JEUS_CMD=`jps |grep $JEUS_PID |awk '{print $2}'`

        printf "%-20s%-50s%-20s%-30s\n" "JEUS" "$JEUS_CMD" "$JEUS_PID" "$JEUS_STARTTIME"
    done

    # HyperLoader
    HYPER_PIDS=(`ps -ef|grep hyper |grep -v grep |awk '{print $2}'`)
    for HYPER_PID in ${HYPER_PIDS[@]}
    do
        HYPER_STARTTIME=`ps -eo lstart,pid,cmd |grep $HYPER_PID|grep -vE "grep|cub_admin"| awk '{
        cmd="date -d\""$1 FS $2 FS $3 FS $4 FS $5"\" +\047%Y-%m-%d %H:%M:%S\047"; 
        cmd | getline d; close(cmd); $1=$2=$3=$4=$5=""; printf "%s\n",d$0 }' 2>/dev/null |awk '{print $1" "$2}'`
        HYPER_CMD="Loader"

        printf "%-20s%-50s%-20s%-30s\n" "HyperLoader" "$HYPER_CMD" "$HYPER_PID" "$HYPER_STARTTIME"
    done
    echo
    echo
}

function ft_step_portscan(){
STEP="5"
    echo "######## $STEP. Port check ########"
    echo "Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    "
    netstat -nlp |grep tcp 
    echo
    echo
}

function ft_step_space(){
STEP="6"
    echo "######## $STEP. Disk space usage ########"
    echo "######## $STEP.1. Total size ########"
    df -h
    echo
    echo "######## $STEP.2. Size on by type ########"
    SYSMASTER_HOME_SIZE=(`df -h $SYSMASTER_HOME|grep -v Mounted`)
    TB_HOME_SIZE=(`df -h $TB_HOME|grep -v Mounted`)
    JEUS_HOME_SIZE=(`df -h $JEUS_HOME|grep -v Mounted`)
    HL_HOME_SIZE=(`df -h $HL_HOME|grep -v Mounted`)
    PROOBJECT_HOME_SIZE=(`df -h $PROOBJECT_HOME|grep -v Mounted`)
    printf "%-15s%-10s%-10s%-10s%-10s%-20s\n" "Home type" "Size" "Used" "Avail" "Use%" "Mounted on"
    printf "%-15s%-10s%-10s%-10s%-10s%-20s\n" "SYSMASTER" "${SYSMASTER_HOME_SIZE[1]}" "${SYSMASTER_HOME_SIZE[2]}" "${SYSMASTER_HOME_SIZE[3]}" "${SYSMASTER_HOME_SIZE[4]}" "${SYSMASTER_HOME_SIZE[5]}"
    printf "%-15s%-10s%-10s%-10s%-10s%-20s\n" "SMDB" "${TB_HOME_SIZE[1]}" "${TB_HOME_SIZE[2]}" "${TB_HOME_SIZE[3]}" "${TB_HOME_SIZE[4]}" "${TB_HOME_SIZE[5]}"
    printf "%-15s%-10s%-10s%-10s%-10s%-20s\n" "JEUS" "${JEUS_HOME_SIZE[1]}" "${JEUS_HOME_SIZE[2]}" "${JEUS_HOME_SIZE[3]}" "${JEUS_HOME_SIZE[4]}" "${JEUS_HOME_SIZE[5]}"
    printf "%-15s%-10s%-10s%-10s%-10s%-20s\n" "HyperLoader" "${HL_HOME_SIZE[1]}" "${HL_HOME_SIZE[2]}" "${HL_HOME_SIZE[3]}" "${HL_HOME_SIZE[4]}" "${HL_HOME_SIZE[5]}"
    printf "%-15s%-10s%-10s%-10s%-10s%-20s\n" "ProObject" "${PROOBJECT_HOME_SIZE[1]}" "${PROOBJECT_HOME_SIZE[2]}" "${PROOBJECT_HOME_SIZE[3]}" "${PROOBJECT_HOME_SIZE[4]}" "${PROOBJECT_HOME_SIZE[5]}"
    echo
    echo "######## $STEP.3. SMDB Talespace usage ########"
function SMDB_TABLESPACE(){   
    tbsql $SMDB_ID/$SMDB_PSW @sql/smdb_tablespace.sql  << EOF
    quit
EOF
}
    SMDB_TABLESPACE |grep -vE "tbSQL|Corporation|Connected|^$|Disconnected"
    echo
    echo
}

function ft_step_cpu(){
STEP="7"
    echo "######## $STEP. CPU Check ########"
    echo "######## $STEP.1. vmstat ########"
    vmstat 1 5
    echo
    echo "######## $STEP.2. TOP CPU (10 process) ########"
    echo "USER        PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND"
    ps -aux  |grep -v "%CPU"|sort -k 3 -r |head -n 10
    echo
    echo
}

function ft_step_smdb(){
STEP="8"
    echo "######## $STEP. SMDB Check ########"
    function SMDB_REGIMON(){
     tbsql $SMDB_ID/$SMDB_PSW @sql/smdb_regimon.sql  << EOF
    quit
EOF
    }
    SMDB_REGIMON |grep -vE "tbSQL|Corporation|Connected|^$|Disconnected"
    echo
    echo
}
echo
function ft_step_jues(){
SETP="9"
    echo "######## $STEP. JEUS Check ########"
    function JEUS_MON(){
        jeusadmin -u $JEUS_ID -p $JEUS_PSW << EOF
        si
        application-info
EOF
    }
    JEUS_MON 
    echo
    echo
}

function ft_step_log(){
STEP="10"
    echo "######## $STEP. Log check ########"
    cd $SYSMASTER_HOME

    # SMDB
    echo "######## $STEP.1. SMDB Log ########"
    printf "%-20s%-100s\n" "SMDB" "LOG FILE"
    echo "-----------------------------------"
    SMDB_LOGFILES=(`find $SMDB_LOG_PATH -mtime -$RECENT_DAYS -name 'sys.log' -o -name '*.out'`)
    
    if [ $SMDB_LOGFILES -z ]
    then
        echo "No changes in the recently $RECENT_DAYS days."
    fi

    for SMDB_LOGFILE in ${SMDB_LOGFILES[@]}
    do
        printf "%-20s%-100s\n" "SMDB" "$SMDB_LOGFILE"
    done

    echo
    # JEUS
    echo "######## $STEP.2. JEUS Log ########"
    printf "%-20s%-100s\n" "JEUS" "LOG FILE"    
    echo "-----------------------------------"
    JEUS_LOGFILES=(`find jeus8/domains -mtime -$RECENT_DAYS -name 'access_*.log' -o -name 'JeusServer*.log' |xargs grep -i "OutOfMe"`)
    if [ $JEUS_LOGFILES -z ]
    then
        echo "No changes in the recently $RECENT_DAYS days."
    fi

    for JEUS_LOGFILE in ${JEUS_LOGFILES[@]}
    do
        printf "%-20s%-100s\n" "JUES" "$JEUS_LOGFILE"
    done
    echo

    # HyperLoader
    echo "######## $STEP.3. HyperLoader Log ########"
    printf "%-20s%-100s\n" "HyperLoader" "LOG FILE"
    echo "-----------------------------------"
    HYPER_LOGFILES=(`find hyperLoader -mtime -$RECENT_DAYS -name '*.log' -o -name '*.out'`)
    
    if [ $HYPER_LOGFILES -z ]
    then
        echo "No changes in the recently $RECENT_DAYS days."
    fi

    for HYPER_LOGFILE in ${HYPER_LOGFILES[@]}
    do
        printf "%-20s%-100s\n" "HyperLoader" "$HYPER_LOGFILE"
    done
    echo

    # ProObject
    echo "######## $STEP.4. ProObject Log ########"
    printf "%-20s%-100s\n" "ProObject" "LOG FILE"
    echo "-----------------------------------"
    PROOB_LOGFILES=(`find proobject7 -mtime -$RECENT_DAYS -name 'app.log'`)

    if [ $PROOB_LOGFILES -z ]
    then
        echo "No changes in the recently $RECENT_DAYS days."
    fi

    for PROOB_LOGFILE in ${PROOB_LOGFILES[@]}
    do
        printf "%-20s%-100s\n" "ProObject" "$PROOB_LOGFILE"
    done
    echo
    echo
}
##

## Program function running
function main(){
    ft_step_env
    ft_step_version
    ft_step_system
    ft_step_uptime
    ft_step_portscan
    ft_step_space
    ft_step_cpu
    ft_step_smdb
    ft_step_jues
    ft_step_log
}
main 2>/dev/null
##