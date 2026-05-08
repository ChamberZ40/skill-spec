# Skill Chains

Registry of skill input/output relationships.

## Format

```
[upstream-skill] --{output type}--> [downstream-skill]
```

## Chains

[db-connector] --{SQL query results}--> [lark-sheets]
  场景: 从 bmc_nylas/bmc_publisher 查询数据，导出到飞书电子表格
  典型用例: 查询有回复的联盟客邮箱列表 → 写入飞书表格

[publisher-matcher] --{matched list}--> [publisher-review]
[publisher-review] --{confirmed list}--> [email-generator]
[email-generator] --{email content}--> [mail-send-batch]
[mail-query-message] --{thread content}--> [mail-analysis]
[mail-analysis] --{reply suggestion}--> [mail-reply-message]
