# PostgreSQL with zhparser for CloudNative-PG

![Build Status](https://github.com/yourusername/postgres-zhparser/workflows/Build%20PostgreSQL%20with%20zhparser/badge.svg)
![Security Scan](https://github.com/yourusername/postgres-zhparser/workflows/Security%20Scan/badge.svg)

Last updated: 2024-01-01 12:00 UTC

## 支持的版本

- PostgreSQL 15 with zhparser: `ghcr.io/yourusername/postgres-zhparser:15`
- PostgreSQL 16 with zhparser: `ghcr.io/yourusername/postgres-zhparser:16`
- PostgreSQL 17 with zhparser: `ghcr.io/yourusername/postgres-zhparser:17`

## 快速开始

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-zhparser
spec:
  instances: 3
  imageName: ghcr.io/yourusername/postgres-zhparser:17
  
  bootstrap:
    initdb:
      database: myapp
      owner: appuser
      postInitSQL:
        - "CREATE EXTENSION zhparser;"
        - "CREATE TEXT SEARCH CONFIGURATION chinese_zh (PARSER = zhparser);"