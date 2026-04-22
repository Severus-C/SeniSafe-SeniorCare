# SeniSafe Backend

后端服务用于承载药盒识别、药物冲突检查、服药记录同步与急救数据包生成。

## Current Progress

- 已支持 `Multipart UploadFile` 药盒图片上传
- 已接入 JSON 持久化用户画像、药物清单与服药记录
- 已支持药物确认录入与二次冲突校验
- 已支持生成并查询 SOS 数字化急救名片
- 已预埋 PaddleOCR 真实中文 OCR 识别逻辑

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
- 如需启用真实 OCR，请先安装 `PaddlePaddle` 与 `paddleocr`
- 后续可升级为正式数据库与消息推送架构
