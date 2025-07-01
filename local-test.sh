#!/bin/bash
# local-test.sh

set -e

# 先测试镜像是否能正常启动
docker run -d --name test-startup \
  -e POSTGRES_PASSWORD=testpass \
  cnpg-zhparser:debug

# 等待启动
sleep 30

# 检查容器状态
docker ps -a | grep test-startup

# 查看日志
docker logs test-startup

# 如果启动成功，测试扩展
docker exec test-startup psql -U postgres -c "SELECT version();"
docker exec test-startup psql -U postgres -c "CREATE EXTENSION zhparser;"

# 清理
docker stop test-startup
docker rm test-startup