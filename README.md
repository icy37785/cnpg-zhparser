# PostgreSQL with zhparser for CloudNative-PG

![Build Status](https://github.com/icy37785/cnpg-zhparser/workflows/Build%20PostgreSQL%20with%20zhparser/badge.svg)

Last updated: 2025-07-01 12:00 UTC

## 支持的版本

- PostgreSQL 16 with zhparser: `ghcr.io/icy37785/cnpg-zhparser:16`
- PostgreSQL 17 with zhparser: `ghcr.io/icy37785/cnpg-zhparser:17`

## 快速开始

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-zhparser
spec:
  instances: 3
  imageName: ghcr.io/icy37785/cnpg-zhparser:17
  
  bootstrap:
    initdb:
      database: myapp
      owner: appuser
      postInitSQL:
        - "CREATE EXTENSION zhparser;"
        - "CREATE TEXT SEARCH CONFIGURATION chinese_zh (PARSER = zhparser);"