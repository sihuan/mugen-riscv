#!/usr/bin/bash

# Copyright (c) 2022. Huawei Technologies Co.,Ltd.ALL rights reserved.
# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.

# #############################################
# @Author    :   Classicriver_jia
# @Contact   :   classicriver_jia@foxmail.com
# @Date      :   2020.4.27
# @License   :   Mulan PSL v2
# @Desc      :   Login and exit configuration database password
# ############################################
source ${OET_PATH}/libs/locallibs/common_lib.sh
source ../common/mysql_pre.sh
function pre_test() {
    LOG_INFO "Start environment preparation."
    yum list | grep mysql.*-server
    if [ $? -eq 0 ]; then
        rm -rf /var/lib/mysql/*
	pkgs=`yum list | grep mysql.*-server | awk -F ' ' '{print $1}'`
        DNF_INSTALL ${pkgs}
        systemctl start mysqld
    else
        mysql_flag=1
        mysql_pre
    fi
    LOG_INFO "Environmental preparation is over."
}

function run_test() {
    LOG_INFO "Start executing testcase."
    expect -c "
    set timeout 10
    log_file testlog
    spawn mysql -u root -p
    expect {
        \"Enter*\" { send \"${mysql_passwd}\r\";
        expect \"mysql>\" { send \"alter user 'root'@'localhost' identified by '${NODE1_PASSWORD}';\r\"}
        expect \"mysql>\" { send \"create user 'root'@'%' identified by '123456';\r\"}
        expect \"mysql>\" { send \"grant all privileges on *.* to 'root'@'%';\r\"}
        expect \"mysql>\" { send \"flush privileges;\r\"}
        expect \"mysql>\" { send \"exit\r\"}
}
}
expect eof
"
    grep -iE "error|fail|while executing" testlog
    CHECK_RESULT $? 1
    CHECK_RESULT $(grep -ic "Query OK" testlog) 4
    LOG_INFO "End of testcase execution."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    rm -rf testlog
    test -z ${mysql_flag} || clean_mysql
    DNF_REMOVE
    LOG_INFO "Finish environment cleanup."
}

main $@
