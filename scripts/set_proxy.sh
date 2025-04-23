export http_proxy=http://172.17.0.1:7890
export https_proxy=http://172.17.0.1:7890
export http_proxy_server=http://172.17.0.1:7890
export all_proxy_server=http://172.17.0.1:7890


[[ -f /etc/apt/apt.conf ]] || \
sudo bash -c 'cat << EOF > /etc/apt/apt.conf
Acquire::http::Proxy "http://172.17.0.1:7890";
Acquire::https::Proxy "http://172.17.0.1:7890";
EOF'
