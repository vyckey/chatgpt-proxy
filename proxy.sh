#!/bin/bash

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

# 使用nginx进行代理，使用lua进行header校验，参考 https://www.cnblogs.com/jonnyan/p/9824264.html
WORKSPACE=/workspace/chatgpt-proxy
PASSWORD=""

help() {
    clear
    echo "usage: ./proxy.sh [options] command"
    echo -e "\nThese are common proxy commands used in various situations:"
    echo -e "\nCommon Commands:"
    echo -e "\thelp \thelp manul"
    echo -e "\tinstall \tinstall proxy packages"
    echo -e "\tuninstall \tuninstall chatgpt proxy"
    echo -e "\tstart \tstart proxy server"
    echo -e "\trestart \trestart proxy server"
    echo -e "\tstop \tstop proxy server"
    echo -e "\ttest \ttest proxy server"
}

check_installed() {
    if ! command -v $1 >/dev/null 2>&1; then  
        echo -e "${RED}$1 hasn't been installed."
        return
    fi
}

install() {
    if command -v nginx >/dev/null 2>&1; then
        echo "${GREEN}nginx had installed."
        return
    fi

    mkdir -p $WORKSPACE
    cp nginx.conf $WORKSPACE
    sed "s/PASSWORD/${PASSWORD}/g" access_auth.lua > $WORKSPACE/access_auth.lua
    cd $WORKSPACE

    # OpenResty通过汇聚各种设计精良的 Nginx 模块，从而将 Nginx 有效地变成一个强大的通用 Web 应用平台。
    # https://openresty.org/cn/linux-packages.html#ubuntu
    apt-get -y install --no-install-recommends wget gnupg ca-certificates
    wget -O - https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/openresty.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openresty.gpg] http://openresty.org/package/ubuntu $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/openresty.list > /dev/null
    apt-get update
    apt-get -y install --no-install-recommends openresty
    export PATH=$PATH:/usr/local/openresty/nginx/sbin
    echo "export PATH=$PATH:/usr/local/openresty/nginx/sbin" > ~/.bash_rc

    echo "${GREEN}nginx has installed."
    nginx -V
}

install_lua() {
    apt-get install libreadline-dev
    LUA_VERSION=5.3.0
    curl -R -O http://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz && tar zxf lua-$LUA_VERSION.tar.gz
    cd lua-$LUA_VERSION && make linux test && make install && cd .. && rm -rf lua-*
}

uninstall() {
    nginx -s stop

    apt-get --purge remove nginx && apt-get autoremove
    dpkg --get-selections | grep nginx
    apt-get --purge remove nginx-core
    apt-get --purge remove nginx-common

    # find / -name openresty | rm -rf
}

start() {
    check_installed nginx
    nginx -c "${WORKSPACE}/nginx.conf"
}

restart() {
    check_installed nginx
    stop
    start
}

stop() {
    check_installed nginx
    nginx -s stop
}

test() {
    echo "ready to check proxy server health..."
    echo "curl http://localhost:80/api/health"
    curl http://localhost:80/api/health
}

action=$1
[[ -z $1 ]] && action=menu
case "$action" in
    help|install|uninstall|start|restart|stop|test)
        ${action}
        ;;
    *)
        echo " arguments error"
        echo " usage: `basename $0` [help|install|uninstall|start|restart|stop|test]"
        ;;
esac
