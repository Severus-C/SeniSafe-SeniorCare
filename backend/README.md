# SeniSafe Backend

后端服务用于承载药盒识别、药物冲突检查、服药记录同步与急救数据包生成。

## Run

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Core Routes

- `POST /medication/recognize`
- `POST /medication/confirm`
- `POST /emergency/prepare_packet`
- `GET /emergency/packet/{user_id}`
- `GET /health`

## Notes

- 当前存储层使用 JSON 持久化，便于本地开发与联调
- 后续可升级为正式数据库与消息推送架构
