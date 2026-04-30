# MoonTV API 使用文档

## 项目概述

MoonTV 是一个基于 Next.js 构建的视频播放和管理系统，提供了丰富的 API 接口用于实现用户认证、内容搜索、视频详情获取、播放记录管理、收藏管理等功能。

## API 基础信息

### 认证方式

- **Cookie 认证**：系统使用 `user_auth` Cookie 进行用户认证
- **认证流程**：用户通过登录 API 获取认证 Cookie，后续请求会自动携带该 Cookie

### 请求/响应格式

- **请求格式**：支持 GET、POST、PUT、DELETE 请求，POST/PUT 请求使用 JSON 格式
- **响应格式**：所有 API 响应均为 JSON 格式
- **状态码**：标准 HTTP 状态码

### 基础 URL

所有 API 接口的基础 URL 为：`/api`

### API 分类

根据访问权限，API 分为三类：

1. **公开 API**：无需认证即可访问
2. **需要认证的 API**：需要用户登录后携带有效 Cookie 才能访问
3. **管理员专用 API**：需要管理员（站长）权限才能访问

---

## 公开 API（无需认证）

### 1. 根 API

#### 接口信息

- **路径**：`/api`
- **方法**：GET, OPTIONS
- **功能**：提供服务器状态信息和成人内容过滤模式检测，OPTIONS 方法用于处理 CORS 预检请求

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| adult | string | 否 | 成人内容模式，值为 `1` 或 `true` 时启用完整内容模式 |
| filter | string | 否 | 过滤模式，值为 `off` 时关闭过滤 |

#### 请求头

| 头名 | 类型 | 必填 | 描述 |
|------|------|------|------|
| X-Content-Mode | string | 否 | 内容模式，值为 `adult` 时启用完整内容模式 |

#### 响应示例

```json
{
  "status": "ok",
  "version": "1.0.0",
  "authenticated": true,
  "adultFilterEnabled": true,
  "message": "家庭安全模式 - 成人内容已过滤"
}
```

#### 响应头

| 头名 | 描述 |
|------|------|
| Access-Control-Allow-Origin | 允许的跨域来源，设置为 `*` |
| Access-Control-Allow-Methods | 允许的 HTTP 方法，包括 `GET, OPTIONS` |
| Access-Control-Allow-Headers | 允许的请求头，包括 `Content-Type, X-Content-Mode` |
| X-Adult-Filter | 成人内容过滤状态，值为 `enabled` 或 `disabled` |

---

### 2. 登录 API

#### 接口信息

- **路径**：`/api/login`
- **方法**：POST
- **功能**：用户登录，获取认证 Cookie

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| password | string | 是（localstorage 模式） | 登录密码 |
| username | string | 是（数据库模式） | 用户名 |
| password | string | 是（数据库模式） | 登录密码 |

#### 响应示例

```json
{
  "ok": true
}
```

#### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 400 | 密码不能为空 | 密码参数缺失 |
| 401 | 密码错误 | 密码验证失败 |
| 401 | 用户名或密码错误 | 数据库模式下验证失败 |
| 401 | 账号被封禁 | 用户已被封禁 |

---

### 3. 注册 API

#### 接口信息

- **路径**：`/api/register`
- **方法**：POST
- **功能**：用户注册，仅支持数据库模式
- **注意**：localStorage 模式不支持注册功能

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| username | string | 是 | 用户名（3-20位，只允许字母、数字和下划线） |
| password | string | 是 | 密码（至少6位） |
| confirmPassword | string | 是 | 确认密码（必须与 password 相同） |
| email | string | 是 | 邮箱（必须是主流邮箱，如 QQ、163、Gmail 等） |
| verificationCode | string | 是 | 邮箱验证码 |

#### 响应示例

```json
{
  "ok": true,
  "message": "注册成功，已自动登录",
  "needDelay": false
}
```

#### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 400 | localStorage 模式不支持用户注册 | 存储模式不支持 |
| 400 | 用户名不能为空 | 用户名缺失 |
| 400 | 密码不能为空 | 密码缺失 |
| 400 | 邮箱不能为空 | 邮箱缺失 |
| 400 | 验证码不能为空 | 验证码缺失 |
| 400 | 邮箱格式不正确 | 邮箱格式错误 |
| 400 | 仅支持使用主流邮箱注册 | 邮箱不在支持列表 |
| 400 | 两次输入的密码不一致 | 密码确认不匹配 |
| 400 | 密码长度至少6位 | 密码太短 |
| 400 | 该用户名已被使用 | 用户名冲突 |
| 400 | 该用户名已被注册 | 用户名已存在 |
| 400 | 该邮箱已被注册 | 邮箱已被使用 |
| 400 | 用户名只能包含字母、数字和下划线，长度3-20位 | 用户名格式错误 |
| 403 | 管理员已关闭用户注册功能 | 注册功能已禁用 |
| 400 | 验证码错误或已过期 | 验证码无效 |

---

### 4. 登出 API

#### 接口信息

- **路径**：`/api/logout`
- **方法**：POST
- **功能**：用户登出，清除认证 Cookie

#### 响应示例

```json
{
  "ok": true
}
```

---

### 5. 豆瓣 API

#### 接口信息

- **路径**：`/api/douban`
- **方法**：GET
- **功能**：获取豆瓣电影/电视剧列表
- **认证**：公开

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| type | string | 是 | 类型，可选值为 `tv`（电视剧）或 `movie`（电影） |
| tag | string | 是 | 标签，如 `热门`、`最新`、`豆瓣高分`、`top250` 等 |
| pageSize | number | 否 | 每页数量，默认 16，范围 1-100 |
| pageStart | number | 否 | 分页起始位置，默认 0 |

#### 响应示例

```json
{
  "code": 200,
  "message": "获取成功",
  "list": [
    {
      "id": "123456",
      "title": "肖申克的救赎",
      "poster": "https://img9.doubanio.com/view/photo/s_ratio_poster/public/p480747492.webp",
      "rate": "9.7",
      "year": ""
    }
  ]
}
```

#### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 400 | 缺少必要参数: type 或 tag | 缺少必需参数 |
| 400 | type 参数必须是 tv 或 movie | type 参数值无效 |
| 400 | pageSize 必须在 1-100 之间 | pageSize 超出范围 |
| 400 | pageStart 不能小于 0 | pageStart 为负数 |
| 500 | 获取豆瓣数据失败 | 豆瓣 API 请求失败 |
| 500 | 获取豆瓣 Top250 数据失败 | Top250 数据获取失败 |

#### 缓存策略

- 缓存时间由系统配置决定（默认使用 `getCacheTime()` 返回值）
- 响应头包含 CDN 缓存控制指令

#### 说明

- 当 tag 为 `top250` 时，会直接从豆瓣电影 Top250 页面抓取数据
- 其他 tag 会调用豆瓣搜索 API 获取数据

---

### 6. 豆瓣 Top250 API

#### 接口信息

- **路径**：`/api/douban?type=movie&tag=top250`
- **方法**：GET
- **功能**：获取豆瓣电影 Top250 榜单

#### 响应示例

```json
{
  "code": 200,
  "message": "获取成功",
  "list": [
    {
      "id": "1292052",
      "title": "肖申克的救赎",
      "poster": "https://img9.doubanio.com/view/photo/s_ratio_poster/public/p480747492.webp",
      "rate": "9.7",
      "year": ""
    }
  ]
}
```

---

### 7. 发送验证码 API

#### 接口信息

- **路径**：`/api/send-verification-code`
- **方法**：POST
- **功能**：发送邮箱验证码

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| email | string | 是 | 邮箱地址 |
| type | string | 否 | 验证码类型，默认为 `register`，可选值为 `register`（注册验证码）或 `其他`（通用验证码） |

#### 响应示例

**成功响应：**

```json
{
  "success": true,
  "message": "验证码已发送，请查收邮件"
}
```

**错误响应：**

```json
{
  "error": "错误信息"
}
```

#### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 400 | 邮箱不能为空 | 邮箱参数缺失 |
| 400 | 邮箱格式不正确 | 邮箱格式错误 |
| 400 | 仅支持使用主流邮箱注册（如QQ、163、Gmail等） | 邮箱不在支持列表 |
| 400 | 该邮箱已被注册 | 邮箱已被使用（仅 register 类型） |
| 429 | 频繁请稍后重试 | 邮箱发送次数超过限制（24小时内最多5次） |
| 500 | 系统暂时无法验证邮箱，请稍后重试 | 数据库查询失败 |
| 500 | 系统暂时无法验证发送次数，请稍后重试 | 检查发送次数失败 |
| 500 | 系统暂时无法存储验证码，请稍后重试 | 验证码存储失败 |
| 500 | 邮件服务器连接失败，请稍后重试 | SMTP连接失败 |
| 500 | 邮件服务器连接超时，请稍后重试 | SMTP连接超时 |
| 500 | 邮件服务器地址解析失败，请稍后重试 | DNS解析失败 |
| 500 | 发送验证码失败，请稍后重试 | 邮件发送失败 |

#### 说明

- 验证码有效期为 **5分钟**
- 每个邮箱24小时内最多发送 **5次** 验证码
- 支持的主流邮箱：gmail.com, qq.com, 163.com, 126.com, outlook.com, hotmail.com, foxmail.com, sina.com, sohu.com, yahoo.com, aliyun.com, icloud.com, live.com, msn.com, 139.com, yeah.net
- 验证码为6位随机数字

---

### 8. 剧集跳过配置 API

#### 接口信息

- **路径**：`/api/episode-skip-config`
- **方法**：GET
- **功能**：获取剧集跳过配置

#### 响应示例

```json
{
  "skipConfigs": []
}
```

---

### 9. 跳过配置 API

#### 接口信息

- **路径**：`/api/skipconfigs`
- **方法**：GET
- **功能**：获取跳过配置列表

#### 响应示例

```json
{
  "configs": []
}
```

---

## 需要认证的 API（登录后可访问）

> 以下 API 需要用户登录后携带有效的 `user_auth` Cookie 才能访问

### 10. 搜索 API

#### 接口信息

- **路径**：`/api/search`
- **方法**：GET
- **功能**：搜索视频内容

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| q | string | 是 | 搜索关键词 |

#### 响应示例

```json
{
  "results": [
    {
      "id": "123",
      "title": "示例视频",
      "poster": "https://example.com/poster.jpg",
      "year": "2023",
      "type_name": "电影",
      "source": "example",
      "source_name": "示例源"
    }
  ]
}
```

---

### 11. 视频详情 API

#### 接口信息

- **路径**：`/api/detail`
- **方法**：GET
- **功能**：获取视频详情和播放链接

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| id | string | 是 | 视频 ID |
| source | string | 是 | 视频来源 |
| title | string | 否 | 视频标题（用于搜索匹配） |

#### 响应示例

```json
{
  "source": "example",
  "source_name": "示例源",
  "id": "123",
  "title": "示例视频",
  "poster": "https://example.com/poster.jpg",
  "year": "2023",
  "douban_id": 123456,
  "desc": "视频描述",
  "episodes": ["https://example.com/ep1.mp4", "https://example.com/ep2.mp4"],
  "episodes_titles": ["第1集", "第2集"],
  "proxyMode": false
}
```

---

### 12. 播放记录 API

#### 接口信息

- **路径**：`/api/playrecords`
- **方法**：GET、POST、DELETE
- **功能**：管理用户播放记录

#### GET 请求

**功能**：获取用户所有播放记录

**响应示例**：

```json
{
  "example+123": {
    "title": "示例视频",
    "source_name": "示例源",
    "index": 1,
    "play_time": 300,
    "total_time": 1200,
    "total_episodes": 2,
    "original_episodes": 2,
    "save_time": 1680000000000
  }
}
```

#### POST 请求

**功能**：保存或更新播放记录

**请求参数**：

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| key | string | 是 | 格式为 `source+id` 的记录键 |
| record | object | 是 | 播放记录对象 |

**record 对象结构**：

| 字段名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| title | string | 是 | 视频标题 |
| source_name | string | 是 | 视频来源名称 |
| index | number | 是 | 当前播放集数 |
| play_time | number | 是 | 当前播放时间（秒） |
| total_time | number | 是 | 总播放时间（秒） |
| total_episodes | number | 是 | 总集数 |
| original_episodes | number | 否 | 原始总集数 |
| save_time | number | 否 | 保存时间戳 |

**响应示例**：

```json
{
  "success": true
}
```

#### DELETE 请求

**功能**：删除播放记录

**请求参数**：

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| key | string | 否 | 格式为 `source+id` 的记录键，不提供则删除所有记录 |

**响应示例**：

```json
{
  "success": true
}
```

---

### 13. 收藏 API

#### 接口信息

- **路径**：`/api/favorites`
- **方法**：GET、POST、DELETE
- **功能**：管理用户收藏

#### GET 请求

**功能**：获取用户所有收藏

**请求参数**：

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| key | string | 否 | 格式为 `source+id`，提供则返回单条收藏 |

**响应示例**：

```json
{
  "example+123": {
    "title": "示例视频",
    "poster": "https://example.com/poster.jpg",
    "year": "2023",
    "type_name": "电影",
    "source_name": "示例源",
    "save_time": 1680000000000
  }
}
```

#### POST 请求

**功能**：添加或更新收藏

**请求参数**：

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| key | string | 是 | 格式为 `source+id` |
| favorite | object | 是 | 收藏对象 |

**favorite 对象结构**：

| 字段名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| title | string | 是 | 视频标题 |
| poster | string | 否 | 海报图片 URL |
| year | string | 否 | 年份 |
| type_name | string | 否 | 类型名称 |
| source_name | string | 是 | 来源名称 |
| save_time | number | 否 | 保存时间戳 |

**响应示例**：

```json
{
  "success": true
}
```

#### DELETE 请求

**功能**：删除收藏

**请求参数**：

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| key | string | 否 | 格式为 `source+id`，不提供则清空所有收藏 |

**响应示例**：

```json
{
  "success": true
}
```

---

### 14. 用户统计 API

#### 接口信息

- **路径**：`/api/user/my-stats`
- **方法**：GET、POST、PUT、DELETE
- **功能**：获取和管理用户个人统计数据
- **认证**：需要登录
- **存储要求**：仅支持 Redis、Upstash 或 Kvrocks 存储类型

#### GET 请求

**功能**：获取用户个人统计数据

**响应示例**：

```json
{
  "totalWatchTime": 3600,
  "totalMovies": 10,
  "totalPlays": 25,
  "firstWatchDate": 1680000000000,
  "lastUpdateTime": 1680100000000,
  "registrationDays": 30,
  "loginDays": 15,
  "loginCount": 5,
  "firstLoginTime": 1679900000000,
  "lastLoginTime": 1680100000000,
  "lastLoginDate": 1680100000000
}
```

#### POST 请求

**功能**：更新用户统计数据（用于智能观看时间统计）

**请求参数**：

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| watchTime | number | 是 | 观看时间（秒） |
| movieKey | string | 是 | 影片键名 |
| timestamp | number | 是 | 时间戳 |
| isRecalculation | boolean | 否 | 是否为重算 |

**响应示例**：

```json
{
  "success": true,
  "userStats": {
    "totalWatchTime": 3700,
    "lastUpdateTime": 1680100000000
  }
}
```

#### PUT 请求

**功能**：记录用户登入时间

**请求参数**：

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| loginTime | number | 是 | 登入时间戳 |

**响应示例**：

```json
{
  "success": true,
  "message": "登入时间记录成功",
  "loginTime": 1680100000000,
  "loginCount": 6
}
```

#### DELETE 请求

**功能**：清除用户统计数据

**响应示例**：

```json
{
  "success": true
}
```

#### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 401 | Unauthorized | 未登录 |
| 401 | 用户不存在 | 用户账户不存在 |
| 401 | 用户已被封禁 | 用户已被禁用 |
| 400 | 当前存储类型不支持播放统计功能，请使用 Redis、Upstash 或 Kvrocks | 存储类型不支持 |
| 400 | 参数错误：需要 watchTime, movieKey, timestamp | 参数缺失 |
| 400 | 参数错误：需要 loginTime | 参数缺失 |
| 500 | Internal Server Error | 服务器内部错误 |
| 500 | 更新用户统计数据失败 | 更新统计数据失败 |
| 500 | 记录登入时间失败 | 记录登入时间失败 |
| 500 | 清除用户统计数据失败 | 清除统计数据失败 |

---

### 15. 修改密码 API

#### 接口信息

- **路径**：`/api/change-password`
- **方法**：POST
- **功能**：修改用户密码
- **认证**：需要登录
- **注意**：localStorage 模式不支持此功能；站长不能通过此接口修改密码

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| newPassword | string | 是 | 新密码 |

#### 响应示例

```json
{
  "ok": true
}
```

#### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 400 | 不支持本地存储模式修改密码 | localStorage 模式不支持 |
| 401 | Unauthorized | 未登录 |
| 400 | 新密码不得为空 | 密码为空 |
| 403 | 站长不能通过此接口修改密码 | 站长权限不可用此接口 |
| 500 | 修改密码失败 | 修改密码操作失败 |

---

### 16. 搜索历史 API

#### 接口信息

- **路径**：`/api/searchhistory`
- **方法**：GET、POST、DELETE
- **功能**：管理用户搜索历史
- **认证**：需要登录

#### GET 请求

**功能**：获取用户搜索历史

**响应示例**：

```json
["搜索关键词1", "搜索关键词2", "搜索关键词3"]
```

#### POST 请求

**功能**：添加搜索历史

**请求参数**：

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| keyword | string | 是 | 搜索关键词 |

**响应示例**：

```json
["搜索关键词1", "搜索关键词2"]
```

#### DELETE 请求

**功能**：清除搜索历史

**请求参数**：

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| keyword | string | 否 | 搜索关键词，不提供则清空所有历史 |

**响应示例**：

```json
{
  "success": true
}
```

#### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 401 | Unauthorized | 未登录 |
| 401 | 用户不存在 | 用户账户不存在 |
| 401 | 用户已被封禁 | 用户已被禁用 |
| 400 | Keyword is required | 关键词缺失 |
| 500 | Internal Server Error | 服务器内部错误 |

#### 说明

- 搜索历史最多保存 20 条

---

### 17. 代理状态 API

#### 接口信息

- **路径**：`/api/proxy-status`
- **方法**：GET
- **功能**：获取代理状态

---

### 18. 缓存 API

#### 接口信息

- **路径**：`/api/cache`
- **方法**：GET、DELETE
- **功能**：管理系统缓存

#### GET 请求

**功能**：获取缓存状态

#### DELETE 请求

**功能**：清除缓存

---

### 19. 解析 API

#### 接口信息

- **路径**：`/api/parse`
- **方法**：GET
- **功能**：解析视频流地址

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| url | string | 是 | 视频 URL |

---

### 20. AI 助手 API

#### 接口信息

- **路径**：`/api/ai-recommend`
- **方法**：POST、GET
- **功能**：智能影视推荐和对话
- **认证**：需要登录

#### POST 请求

**功能**：发送AI推荐请求，支持流式响应

**请求参数**：

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| messages | Array<Message> | 是 | 对话消息数组 |
| stream | boolean | 否 | 是否启用流式响应（推荐 `true`） |
| context | Object | 否 | 视频上下文信息 |
| model | string | 否 | AI 模型名称（覆盖配置） |
| temperature | number | 否 | 温度参数（0-2） |
| max_tokens | number | 否 | 最大 token 数 |

**Message 结构**：

```typescript
interface Message {
  role: 'user' | 'assistant' | 'system';
  content: string;
}
```

**Context 结构**：

```typescript
interface Context {
  title?: string;        // 视频标题
  year?: string;         // 年份
  douban_id?: number;    // 豆瓣 ID
  tmdb_id?: number;      // TMDB ID
  type?: 'movie' | 'tv'; // 类型
  currentEpisode?: number; // 当前集数
}
```

**响应示例**：

**流式响应**：

```
data: {"text": "## 科幻电影推荐\n\n"}
data: {"text": "《银翼杀手2049》 (2017) [科幻/悬疑] - 视觉震撼的未来世界\n"}
data: {"text": "《降临》 (2016) [科幻/剧情] - 语言与时间的深刻思考\n"}
data: {"text": "《湮灭》 (2018) [科幻/恐怖] - 神秘区域的探索之旅"}
data: [DONE]
```

**非流式响应**：

```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677825464,
  "model": "gpt-3.5-turbo",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "## 科幻电影推荐\n\n《银翼杀手2049》 (2017) [科幻/悬疑] - 视觉震撼的未来世界\n《降临》 (2016) [科幻/剧情] - 语言与时间的深刻思考\n《湮灭》 (2018) [科幻/恐怖] - 神秘区域的探索之旅"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 50,
    "total_tokens": 60
  },
  "recommendations": [
    {
      "title": "银翼杀手2049",
      "year": "2017",
      "genre": "科幻/悬疑",
      "description": "视觉震撼的未来世界"
    }
  ]
}
```

**YouTube 视频解析响应**：

```json
{
  "id": "chatcmpl-456",
  "object": "chat.completion",
  "created": 1677825465,
  "model": "gpt-3.5-turbo",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "我识别到您发送了YouTube视频链接，正在为您解析视频信息..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 20,
    "completion_tokens": 10,
    "total_tokens": 30
  },
  "videoLinks": [
    {
      "videoId": "dQw4w9WgXcQ",
      "originalUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "title": "Rick Astley - Never Gonna Give You Up",
      "channelName": "Rick Astley",
      "thumbnail": "https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg",
      "playable": true,
      "embedUrl": "https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1&rel=0"
    }
  ],
  "type": "video_link_parse"
}
```

**错误响应**：

```json
{
  "error": "API密钥无效，请联系管理员检查配置",
  "details": "Invalid authentication credentials"
}
```

#### GET 请求

**功能**：获取AI推荐历史

**响应示例**：

```json
{
  "history": [
    {
      "timestamp": "2024-01-01T00:00:00.000Z",
      "messages": [
        {
          "role": "user",
          "content": "推荐几部科幻电影"
        }
      ],
      "response": "## 科幻电影推荐\n\n《银翼杀手2049》 (2017) [科幻/悬疑] - 视觉震撼的未来世界"
    }
  ],
  "total": 1
}
```

#### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 401 | Unauthorized | 未登录 |
| 403 | 您无权使用AI推荐功能，请联系管理员开通权限 | 权限不足 |
| 403 | AI推荐功能未启用 | 功能未启用 |
| 400 | Invalid messages format | 消息格式错误 |
| 500 | AI服务暂时不可用，请稍后重试 | AI服务错误 |
| 500 | API密钥无效，请联系管理员检查配置 | API密钥错误 |
| 500 | API请求频率限制，请稍后重试 | 频率限制 |
| 500 | 请求参数错误，请检查输入内容 | 请求参数错误 |
| 500 | AI服务器错误，请稍后重试 | AI服务器错误 |

#### 功能特性

- **多模型支持**：OpenAI、DeepSeek、智谱AI等
- **Tavily搜索**：支持联网搜索（免费模式）
- **YouTube集成**：视频链接解析和搜索推荐
- **智能协调器**：自动分析意图，选择最佳数据源
- **流式响应**：实时打字效果，提升用户体验
- **结构化推荐**：提取电影信息为结构化数据
- **上下文理解**：结合当前视频上下文提供相关推荐

#### 配置要求

管理员需要在后台配置以下信息：

- **AI 模型配置**：
  - API 地址（如 `https://api.openai.com/v1`）
  - API 密钥
  - 模型名称（如 `gpt-3.5-turbo`）
  - 温度和最大 token 数

- **Tavily 搜索配置**（可选，免费模式）：
  - 启用智能协调器
  - 启用联网搜索
  - Tavily API Keys

#### 使用示例

**基本请求**：

```javascript
const response = await fetch('/api/ai-recommend', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    messages: [
      {
        role: 'user',
        content: '推荐几部科幻电影'
      }
    ],
    stream: true
  })
});

// 处理流式响应
if (response.ok && response.body) {
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let fullContent = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    
    const chunk = decoder.decode(value);
    const lines = chunk.split('\n').filter(line => line.trim() !== '');
    
    for (const line of lines) {
      if (line.startsWith('data: ')) {
        const data = line.slice(6);
        if (data === '[DONE]') break;
        
        try {
          const json = JSON.parse(data);
          if (json.text) {
            console.log('AI:', json.text);
            fullContent += json.text;
          }
        } catch (e) {}
      }
    }
  }
  
  console.log('完整响应:', fullContent);
}
```

**带上下文的请求**：

```javascript
const response = await fetch('/api/ai-recommend', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    messages: [
      {
        role: 'user',
        content: '有类似的电影推荐吗？'
      }
    ],
    context: {
      title: '星际穿越',
      year: '2014',
      type: 'movie'
    },
    stream: true
  })
});
```

---

## 管理员专用 API（需要站长权限）

> 以下 API 需要管理员（站长）权限才能访问，即 `authInfo.username === process.env.USERNAME`

### 20. 收藏统计 API

#### 接口信息

- **路径**：`/api/favorites/stats`
- **方法**：GET
- **功能**：统计所有用户的收藏数据（管理员专用）

#### 响应示例

```json
{
  "summary": {
    "total_users": 10,
    "total_favorites": 500,
    "avg_favorites": "50.00",
    "max_favorites": 200,
    "min_favorites": 5,
    "stats_duration": "5.23s"
  },
  "distribution": {
    "0-10": 3,
    "11-50": 4,
    "51-100": 2,
    "101-200": 1,
    "201-500": 0,
    "500+": 0
  },
  "performance": {
    "< 5s": 9,
    "5-15s": 1,
    "15-25s": 0,
    "> 25s": 0
  },
  "slowest_queries": [
    {
      "username": "user1",
      "count": 200,
      "queryTime": "12.35s"
    }
  ],
  "users": [
    {
      "username": "user1",
      "count": 200,
      "queryTime": 12350,
      "status": "success"
    }
  ],
  "warnings": ["有用户收藏数超过 200，建议考虑分页加载"],
  "recommendations": ["建议实施分页加载优化用户体验"]
}
```

---

### 21. 管理员播放统计 API

#### 接口信息

- **路径**：`/api/admin/play-stats`
- **方法**：GET
- **功能**：获取系统播放统计数据（管理员专用）

---

### 22. 管理员性能监控 API

#### 接口信息

- **路径**：`/api/admin/performance`
- **方法**：GET
- **功能**：获取系统性能监控数据（管理员专用）

---

### 23. 管理员配置 API

#### 接口信息

- **路径**：`/api/admin/config`
- **方法**：GET、POST
- **功能**：管理系统配置（管理员专用）

---

### 24. 管理员用户管理 API

#### 接口信息

- **路径**：`/api/admin/user`
- **方法**：GET、POST、PUT、DELETE
- **功能**：管理用户（管理员专用）

---

### 25. 管理员重置 API

#### 接口信息

- **路径**：`/api/admin/reset`
- **方法**：POST
- **功能**：执行系统重置操作（管理员专用）

---

### 26. 管理员缓存管理 API

#### 接口信息

- **路径**：`/api/admin/cache`
- **方法**：GET、DELETE
- **功能**：管理系统缓存（管理员专用）

---

### 27. 管理员 Emby 管理 API

#### 接口信息

- **路径**：`/api/admin/emby`
- **方法**：GET、POST
- **功能**：管理 Emby 连接配置（管理员专用）

---

### 28. 管理员数据导出 API

#### 接口信息

- **路径**：`/api/admin/data_migration/export`
- **方法**：GET
- **功能**：导出系统数据（管理员专用）

---

### 29. 管理员数据导入 API

#### 接口信息

- **路径**：`/api/admin/data_migration/import`
- **方法**：POST
- **功能**：导入系统数据（管理员专用）

---

## 其他 API 端点

### 公开数据类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/bing-wallpaper` | GET | 获取必应壁纸 | 公开 |
| `/api/release-calendar` | GET | 获取发布日历 | 公开 |
| `/api/server-config` | GET | 获取服务器配置 | 公开 |
| `/api/announcement` | GET | 获取公告 | 公开 |

#### 1. 公告 API

##### 接口信息

- **路径**：`/api/announcement`
- **方法**：GET
- **功能**：获取系统公告
- **认证**：公开

##### 响应示例

```json
{
  "ok": true,
  "announcement": "这里是公告内容"
}
```

##### 错误响应

```json
{
  "ok": false,
  "error": "获取公告失败",
  "details": "错误详情"
}
```

#### 2. 服务器配置 API

##### 接口信息

- **路径**：`/api/server-config`
- **方法**：GET
- **功能**：获取服务器配置信息
- **认证**：公开

##### 响应示例

```json
{
  "SiteName": "MoonTV",
  "StorageType": "redis",
  "Version": "1.0.0",
  "DownloadEnabled": true,
  "TelegramAuthConfig": {
    "enabled": true,
    "botUsername": "example_bot",
    "buttonSize": "large",
    "showAvatar": true,
    "requestWriteAccess": false
  },
  "OIDCProviders": [
    {
      "id": "provider1",
      "name": "示例OIDC",
      "buttonText": "使用OIDC登录",
      "issuer": "https://issuer.example.com"
    }
  ]
}
```

##### 说明

- 该 API 返回公开可用的配置信息
- 敏感信息（如密码、密钥等）不会被返回
- 支持内部请求（通过 `x-internal-request: true` 请求头）获取特定配置（如信任网络配置）

#### 3. 必应壁纸 API

##### 接口信息

- **路径**：`/api/bing-wallpaper`
- **方法**：GET
- **功能**：获取随机壁纸
- **认证**：公开

##### 响应示例

```json
{
  "url": "https://www.bing.com/th?id=OHR.ExampleWallpaper",
  "copyright": "壁纸版权信息",
  "title": "壁纸标题",
  "source": "bing"
}
```

##### 说明

- 70% 概率返回 Bing 壁纸，30% 概率返回 Lorem Picsum 壁纸
- Bing 壁纸从过去 0-7 天中随机选择
- 如果所有源都失败，则返回 Lorem Picsum 作为备用

### 需要认证的 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/user/emby-config` | GET、POST | Emby 用户配置 | 需要认证 |
| `/api/favorites/stats` | GET | 收藏统计 | 管理员 |
| `/api/ai-recommend` | GET | AI 推荐 | 需要认证 |
| `/api/watch-room/stats` | GET | 观看室统计 | 需要认证 |
| `/api/watch-room/config` | GET、POST | 观看室配置 | 需要认证 |
| `/api/video-cache/stats` | GET | 视频缓存统计 | 需要认证 |
| `/api/video-cache/cleanup` | POST | 清理视频缓存 | 需要认证 |

### 代理类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/proxy/stream` | GET | 流媒体代理 | 需要认证 |
| `/api/proxy/youtube` | GET | YouTube 代理 | 需要认证 |
| `/api/proxy/bangumi` | GET | Bangumi 代理 | 需要认证 |
| `/api/proxy/cms` | GET | CMS 代理 | 需要认证 |
| `/api/proxy/m3u8` | GET | M3U8 代理 | 需要认证 |
| `/api/proxy/segment` | GET | 分片代理 | 需要认证 |
| `/api/proxy/logo` | GET | Logo 代理 | 需要认证 |
| `/api/proxy/key` | GET | 密钥代理 | 需要认证 |
| `/api/proxy/shortdrama` | GET | 短剧代理 | 需要认证 |
| `/api/video-proxy` | GET | 视频代理 | 需要认证 |
| `/api/image-proxy` | GET | 图片代理 | 需要认证 |

### 直播类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/live/channels` | GET | 获取频道列表 | 公开 |
| `/api/live/epg` | GET | 获取电子节目单 | 公开 |
| `/api/live/sources` | GET | 获取直播源 | 需要认证 |
| `/api/live/merged` | GET | 获取合并后的节目单 | 公开 |
| `/api/live/precheck` | GET | 预检直播源 | 公开 |

### 短剧类 API

#### 接口信息

短剧类 API 用于获取短剧的分类、列表、详情、搜索等功能。

---

#### 8. 短剧分类 API

##### 接口信息

- **路径**：`/api/shortdrama/categories`
- **方法**：GET
- **功能**：获取短剧分类列表
- **认证**：公开

##### 响应示例

```json
[
  {
    "type_id": 1,
    "type_name": "短剧"
  }
]
```

##### 缓存策略

- 缓存时间：4小时（14400秒）
- 响应头包含 `X-Cache-Duration: 4hour`

---

#### 9. 短剧列表 API

##### 接口信息

- **路径**：`/api/shortdrama/list`
- **方法**：GET
- **功能**：获取短剧列表
- **认证**：公开

##### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| categoryId | number | 是 | 分类 ID |
| page | number | 否 | 页码，默认 1 |
| size | number | 否 | 每页数量，默认 20 |

##### 响应示例

```json
{
  "list": [
    {
      "id": 123,
      "name": "示例短剧",
      "cover": "https://example.com/cover.jpg",
      "update_time": "2024-01-01T00:00:00.000Z",
      "score": 8.5,
      "episode_count": 24,
      "description": "短剧描述",
      "author": "作者",
      "backdrop": "https://example.com/backdrop.jpg",
      "vote_average": 8.5
    }
  ],
  "hasMore": true
}
```

##### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 400 | 缺少必要参数: categoryId | 分类 ID 缺失 |
| 400 | 参数格式错误 | 参数格式不正确 |
| 500 | 服务器内部错误 | 服务器错误 |

##### 缓存策略

- 缓存时间：2小时（7200秒）
- 响应头包含 `X-Cache-Duration: 2hour`

---

#### 10. 短剧搜索 API

##### 接口信息

- **路径**：`/api/shortdrama/search`
- **方法**：GET
- **功能**：搜索短剧
- **认证**：公开

##### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| query | string | 是 | 搜索关键词 |
| page | number | 否 | 页码，默认 1 |
| size | number | 否 | 每页数量，默认 20 |

##### 响应示例

```json
{
  "list": [
    {
      "id": 123,
      "name": "示例短剧",
      "cover": "https://example.com/cover.jpg",
      "update_time": "2024-01-01T00:00:00.000Z",
      "score": 8.5,
      "episode_count": 24,
      "description": "短剧描述",
      "author": "作者",
      "backdrop": "https://example.com/backdrop.jpg",
      "vote_average": 8.5
    }
  ],
  "hasMore": true
}
```

##### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 400 | 缺少必要参数: query | 搜索关键词缺失 |
| 400 | 参数格式错误 | 参数格式不正确 |
| 500 | 服务器内部错误 | 服务器错误 |

##### 缓存策略

- 缓存时间：1小时（3600秒）
- 响应头包含 `X-Cache-Duration: 1hour`

---

#### 11. 短剧详情 API

##### 接口信息

- **路径**：`/api/shortdrama/detail`
- **方法**：GET
- **功能**：获取短剧详情
- **认证**：需要认证

##### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| id | number | 是 | 短剧 ID |
| episode | number | 否 | 集数，默认 1 |
| name | string | 否 | 短剧名称（用于备用 API） |

##### 响应示例

```json
{
  "id": "123",
  "title": "示例短剧",
  "poster": "https://example.com/poster.jpg",
  "episodes": ["shortdrama:123:0", "shortdrama:123:1"],
  "episodes_titles": ["第1集", "第2集"],
  "source": "shortdrama",
  "source_name": "短剧",
  "year": "2024",
  "desc": "短剧描述",
  "type_name": "短剧",
  "drama_name": "示例短剧"
}
```

##### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 400 | 缺少必要参数: id | 短剧 ID 缺失 |
| 400 | 参数格式错误 | 参数格式不正确 |
| 400 | 解析失败 | 短剧解析失败 |
| 500 | 服务器内部错误 | 服务器错误 |

---

#### 12. 短剧集数 API

##### 接口信息

- **路径**：`/api/shortdrama/episode-count`
- **方法**：GET
- **功能**：获取短剧总集数
- **认证**：需要认证

##### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| id | number | 是 | 短剧 ID |

---

#### 13. 短剧推荐 API

##### 接口信息

- **路径**：`/api/shortdrama/recommend`
- **方法**：GET
- **功能**：获取短剧推荐
- **认证**：需要认证

---

#### 14. 短剧解析 API

##### 接口信息

- **路径**：`/api/shortdrama/parse`
- **方法**：GET
- **功能**：解析短剧播放地址
- **认证**：需要认证

### 搜索类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/search` | GET | 搜索视频 | 需要认证 |
| `/api/search/one` | GET | 单源搜索 | 需要认证 |
| `/api/search/resources` | GET | 资源搜索 | 需要认证 |
| `/api/search/suggestions` | GET | 搜索建议 | 公开 |
| `/api/search/ws` | WS | WebSocket 搜索 | 需要认证 |
| `/api/netdisk/search` | GET | 网盘搜索 | 需要认证 |
| `/api/source-browser/search` | GET | 源浏览器搜索 | 需要认证 |
| `/api/source-browser/list` | GET | 源列表 | 需要认证 |
| `/api/source-browser/categories` | GET | 源分类 | 需要认证 |
| `/api/source-browser/sites` | GET | 源站点 | 需要认证 |

### 源测试类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/source-test` | GET | 源测试 | 需要认证 |
| `/api/source-test/sources` | GET | 测试源 | 需要认证 |
| `/api/source-weights` | GET、POST | 源权重 | 需要认证 |
| `/api/sources` | GET | 获取源列表 | 需要认证 |
| `/api/admin/source` | GET、POST、PUT、DELETE | 源管理 | 管理员 |
| `/api/admin/source/validate` | POST | 验证源 | 管理员 |

### Emby 类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/emby/list` | GET | 获取 Emby 列表 | 需要认证 |
| `/api/emby/search` | GET | Emby 搜索 | 需要认证 |
| `/api/emby/detail` | GET | Emby 详情 | 需要认证 |
| `/api/emby/sources` | GET | Emby 源 | 需要认证 |
| `/api/emby/public-sources` | GET | 公共源 | 公开 |
| `/api/emby/views` | GET | Emby 视图 | 需要认证 |
| `/api/admin/emby` | GET、POST | Emby 管理 | 管理员 |
| `/api/admin/emby/import` | POST | Emby 导入 | 管理员 |
| `/api/admin/emby/export` | GET | Emby 导出 | 管理员 |

### 订阅类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/admin/config_subscription/fetch` | POST | 获取订阅配置 | 管理员 |

### Telegram 类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/telegram/verify` | POST | Telegram 验证 | 公开 |
| `/api/telegram/send-magic-link` | POST | 发送魔法链接 | 公开 |
| `/api/telegram/set-webhook` | POST | 设置 Webhook | 管理员 |
| `/api/telegram/webhook` | POST | Webhook 处理 | 公开 |

### OIDC 类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/auth/oidc/login` | GET | OIDC 登录 | 公开 |
| `/api/auth/oidc/callback` | GET | OIDC 回调 | 公开 |
| `/api/auth/oidc/complete-register` | POST | OIDC 完成注册 | 公开 |
| `/api/auth/oidc/session-info` | GET | OIDC 会话信息 | 需要认证 |
| `/api/admin/oidc-discover` | GET | OIDC 发现 | 管理员 |

### ACG 类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/acg/mikan` | GET | Mikan 动漫 | 需要认证 |
| `/api/acg/dmhy` | GET | DMHY 动漫 | 需要认证 |
| `/api/acg/acgrip` | GET | ACGRip | 需要认证 |

### TVBox 类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/tvbox` | GET | TVBox 主接口 | 需要认证 |
| `/api/tvbox/search` | GET | TVBox 搜索 | 需要认证 |
| `/api/tvbox/health` | GET | TVBox 健康检查 | 公开 |
| `/api/tvbox/spider-status` | GET | 爬虫状态 | 需要认证 |
| `/api/tvbox/smart-health` | GET | 智能健康检查 | 需要认证 |
| `/api/tvbox/diagnose` | GET | TVBox 诊断 | 需要认证 |
| `/api/tvbox/jar-fix` | POST | JAR 修复 | 管理员 |
| `/api/tvbox/jar-diagnostic` | GET | JAR 诊断 | 需要认证 |
| `/api/tvbox-config` | GET、POST | TVBox 配置 | 需要认证 |
| `/api/admin/tvbox-proxy` | GET、POST | TVBox 代理配置 | 管理员 |
| `/api/admin/tvbox-security` | GET、POST | TVBox 安全配置 | 管理员 |

### 豆瓣增强类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/douban/details` | GET | 豆瓣详情 | 需要认证 |
| `/api/douban/comments` | GET | 豆瓣评论 | 需要认证 |
| `/api/douban/recommends` | GET | 豆瓣推荐 | 需要认证 |
| `/api/douban/categories` | GET | 豆瓣分类 | 公开 |
| `/api/douban/celebrity-works` | GET | 明星作品 | 需要认证 |
| `/api/douban/refresh-trailer` | POST | 刷新预告片 | 需要认证 |

### TMDB 类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/tmdb/actor` | GET | TMDB 演员信息 | 需要认证 |

### YouTube 类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/youtube/search` | GET | YouTube 搜索 | 需要认证 |
| `/api/admin/youtube` | GET、POST | YouTube 管理 | 管理员 |

### 弹幕类 API

弹幕类 API 用于获取外部弹幕数据，支持从多个视频平台获取弹幕，采用多层级容错机制确保弹幕数据的稳定获取。

---

#### 1. 外部弹幕获取 API

##### 接口信息

- **路径**：`/api/danmu-external`
- **方法**：GET
- **功能**：获取外部弹幕数据
- **认证**：需要认证
- **默认配置**：使用 `https://smonedanmu.vercel.app` 作为弹幕源

##### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| douban_id | string | 否 | 豆瓣 ID（与 title 二选一） |
| title | string | 否 | 视频标题（与 douban_id 二选一，建议同时提供以提高匹配精度） |
| year | string | 否 | 年份（用于更精确的年份匹配） |
| episode | string | 否 | 集数（指定获取第几集的弹幕） |
| episode_id | string | 否 | 手动匹配的 episodeId（用于手动匹配模式，优先级最高） |

##### 请求示例

```javascript
// 方式一：通过标题获取弹幕
fetch('/api/danmu-external?title=进击的巨人&year=2013&episode=1')

// 方式二：通过豆瓣ID获取弹幕
fetch('/api/danmu-external?douban_id=10456147&episode=1')

// 方式三：手动匹配模式（直接指定 episodeId）
fetch('/api/danmu-external?episode_id=12345')
```

##### 响应示例

```json
{
  "danmu": [
    {
      "text": "这集太燃了！",
      "time": 10.5,
      "color": "#FFFFFF",
      "mode": 0
    },
    {
      "text": "前方高能预警",
      "time": 25.3,
      "color": "#FF0000",
      "mode": 1
    }
  ],
  "platforms": [
    {
      "platform": "danmu_api",
      "source": "弹幕API (进击的巨人)",
      "count": 1500
    }
  ],
  "total": 1500
}
```

##### DanmuItem 弹幕对象结构

| 字段名 | 类型 | 描述 |
|-------|------|------|
| text | string | 弹幕文本内容 |
| time | number | 弹幕出现的时间（秒） |
| color | string | 弹幕颜色（十六进制格式，如 #FFFFFF） |
| mode | number | 弹幕模式：0=滚动弹幕，1=顶部弹幕，2=底部弹幕 |

##### 错误码

| 状态码 | error 字段 | 描述 |
|-------|-------------|------|
| 400 | Missing required parameters: douban_id or title | 缺少必需参数（未指定 episode_id 时） |
| 400 | episode_id 无效 | episode_id 参数格式错误（必须为正整数） |
| 500 | 获取外部弹幕失败 | 服务器内部错误 |
| 500 | 手动匹配弹幕获取失败 | 手动匹配模式获取失败 |

##### 数据获取流程

**优先级策略**：

1. **最高优先级**：手动匹配模式（`episode_id` 参数）
   - 直接通过 episodeId 获取弹幕
   - 跳过所有搜索和匹配逻辑

2. **主用方案**：弹幕 API（smonedanmu.vercel.app）
   - 通过标题搜索匹配动漫
   - 优先匹配年份一致的结果
   - 获取剧集列表，选择指定集数
   - 获取对应集数的弹幕

3. **备用方案**：豆瓣页面 + 视频平台
   - 从豆瓣页面提取视频平台链接（B站、腾讯、爱奇艺、优酷等）
   - 使用 XML API（fc.lyz05.cn、danmu.smone.us）获取弹幕
   - 备用：使用 JSON API（danmu.icu）获取弹幕

4. **兜底方案**：caiji.cyou 搜索
   - 搜索视频链接
   - 提取播放平台地址
   - 获取弹幕数据

##### 支持的视频平台

| 平台 | 标识 | 说明 |
|------|------|------|
| B站 | bilibili, bilibili_caiji, bilibili_douban | 支持直接链接和豆瓣跳转链接 |
| 腾讯视频 | tencent, tencent_caiji, tencent_direct | 支持移动端和PC端链接 |
| 爱奇艺 | iqiyi, iqiyi_caiji | 自动转换移动版为PC版 |
| 优酷 | youku, youku_caiji | 自动转换移动版为PC版 |
| 芒果TV | mgtv | 支持标准链接 |

##### 性能优化策略

- **智能分段**：按5分钟时间段分段存储，便于按需加载
- **密度控制**：每段最大500条弹幕，防止弹幕过于密集
- **最大限制**：最多返回20000条弹幕，避免内存溢出
- **去重处理**：基于时间（保留2位小数）+ 文本内容 + 颜色去重
- **批量处理**：每200条弹幕让出一次事件循环，避免阻塞
- **智能采样**：弹幕过多时采用均匀采样，保持时间分布均匀

##### 过滤规则

- 弹幕长度需在2-50字符之间
- 过滤纯符号弹幕（不含中文、英文、数字）
- 过滤纯数字弹幕
- 过滤无意义弹幕（如"弹幕正在赶来"、"视频不错"、"666"等）
- 过滤平台相关内容（如"哔哩哔哩"、"官方弹幕库"）

##### 配置说明

管理员可在后台配置弹幕API：

- **启用/禁用**：全局开关
- **自定义API地址**：替换默认弹幕源
- **自定义Token**：API认证令牌
- **超时时间**：请求超时设置（默认30秒）

---

#### 2. 弹幕搜索 API

##### 接口信息

- **路径**：`/api/danmu-external/search`
- **方法**：GET
- **功能**：搜索弹幕库中的动漫
- **认证**：需要认证

##### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| keyword | string | 是 | 搜索关键词 |

##### 请求示例

```javascript
fetch('/api/danmu-external/search?keyword=进击的巨人')
```

##### 响应示例

```json
{
  "code": 200,
  "message": "获取成功",
  "keyword": "进击的巨人",
  "animes": [
    {
      "animeId": 12345,
      "animeTitle": "进击的巨人 最终季",
      "type": "TV",
      "typeDescription": "电视动画",
      "imageUrl": "https://example.com/cover.jpg",
      "episodes": [
        {
          "episodeId": 67890,
          "episodeTitle": "第1集"
        },
        {
          "episodeId": 67891,
          "episodeTitle": "第2集"
        },
        {
          "episodeId": 67892,
          "episodeTitle": "第3集"
        }
      ]
    }
  ],
  "count": 1
}
```

##### 响应字段说明

| 字段名 | 类型 | 描述 |
|-------|------|------|
| code | number | 状态码（200表示成功） |
| message | string | 响应消息 |
| keyword | string | 搜索关键词 |
| animes | Array | 动漫列表 |
| animes[].animeId | number | 动漫ID |
| animes[].animeTitle | string | 动漫标题 |
| animes[].type | string | 类型（TV/OAD/剧场版等） |
| animes[].typeDescription | string | 类型描述 |
| animes[].imageUrl | string | 封面图片URL |
| animes[].episodes | Array | 剧集列表 |
| animes[].episodes[].episodeId | number | 集ID（可用于手动匹配） |
| animes[].episodes[].episodeTitle | string | 集标题 |
| count | number | 匹配数量 |

##### 错误码

| 状态码 | code | message | 描述 |
|-------|------|---------|------|
| 400 | 400 | 缺少必要参数: keyword | 关键词缺失 |
| 503 | 503 | 弹幕API未启用 | 弹幕 API 未启用 |
| 502 | 502 | 弹幕搜索失败: HTTP xxx | 弹幕 API 请求失败 |
| 502 | 502 | 弹幕搜索异常: 错误信息 | 弹幕搜索异常 |

##### 使用说明

搜索结果中的 `episodeId` 可用于手动匹配模式获取弹幕：

```javascript
// 使用搜索结果中的 episodeId 获取弹幕
fetch('/api/danmu-external?episode_id=67890')
```

### 其他管理类 API

| 路径 | 方法 | 功能 | 认证要求 |
|------|------|------|---------|
| `/api/admin/site` | GET、POST | 站点管理 | 管理员 |
| `/api/admin/category` | GET、POST | 分类管理 | 管理员 |
| `/api/admin/cache` | GET、DELETE | 缓存管理 | 管理员 |
| `/api/admin/download-config` | GET、POST | 下载配置 | 管理员 |
| `/api/admin/client-download` | GET | 客户端下载 | 管理员 |
| `/api/admin/trusted-network` | GET、POST | 信任网络 | 管理员 |
| `/api/admin/ai-recommend` | GET、POST | AI 推荐配置 | 管理员 |
| `/api/admin/shortdrama` | GET、POST | 短剧管理 | 管理员 |
| `/api/admin/netdisk` | GET、POST | 网盘管理 | 管理员 |
| `/api/admin/live` | GET、POST | 直播管理 | 管理员 |
| `/api/admin/live/refresh` | POST | 刷新直播 | 管理员 |
| `/api/admin/user-tvbox-token` | GET、POST | TVBox 令牌 | 管理员 |
| `/api/ad-filter` | GET、POST | 广告过滤 | 需要认证 |
| `/api/cron` | GET、POST | 定时任务 | 管理员 |
| `/api/cron/stats` | GET | 定时任务统计 | 管理员 |

---

## 使用示例

### 1. 登录

```javascript
fetch('/api/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ password: 'your_password' })
})
.then(response => response.json())
.then(data => {
  if (data.ok) {
    console.log('登录成功');
  } else {
    console.error('登录失败:', data.error);
  }
});
```

### 2. 注册

```javascript
fetch('/api/register', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    username: 'newuser',
    password: 'password123',
    confirmPassword: 'password123',
    email: 'user@example.com',
    verificationCode: '123456'
  })
})
.then(response => response.json())
.then(data => {
  if (data.ok) {
    console.log('注册成功，已自动登录');
  } else {
    console.error('注册失败:', data.error);
  }
});
```

### 3. 搜索视频

```javascript
fetch('/api/search?q=示例视频')
.then(response => response.json())
.then(data => {
  console.log('搜索结果:', data.results);
});
```

### 4. 获取视频详情

```javascript
fetch('/api/detail?id=123&source=example&title=示例视频')
.then(response => response.json())
.then(data => {
  console.log('视频详情:', data);
});
```

### 5. 保存播放记录

```javascript
fetch('/api/playrecords', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    key: 'example+123',
    record: {
      title: '示例视频',
      source_name: '示例源',
      index: 1,
      play_time: 300,
      total_time: 1200,
      total_episodes: 2
    }
  })
})
.then(response => response.json())
.then(data => {
  if (data.success) {
    console.log('播放记录保存成功');
  }
});
```

### 6. 添加收藏

```javascript
fetch('/api/favorites', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    key: 'example+123',
    favorite: {
      title: '示例视频',
      poster: 'https://example.com/poster.jpg',
      year: '2023',
      type_name: '电影',
      source_name: '示例源'
    }
  })
})
.then(response => response.json())
.then(data => {
  if (data.success) {
    console.log('收藏成功');
  }
});
```

### 7. 获取用户统计

```javascript
fetch('/api/user/my-stats')
.then(response => response.json())
.then(data => {
  console.log('用户统计:', data);
  console.log('总观看时间:', data.totalWatchTime, '秒');
  console.log('收藏数:', data.totalMovies);
});
```

### 8. 登出

```javascript
fetch('/api/logout', {
  method: 'POST'
})
.then(response => response.json())
.then(data => {
  if (data.ok) {
    console.log('登出成功');
  }
});
```

---

## 错误处理

### 常见错误码

| 状态码 | 描述 | 原因 |
|-------|------|------|
| 400 | Bad Request | 请求参数错误或不完整 |
| 401 | Unauthorized | 未认证或认证失败 |
| 403 | Forbidden | 权限不足（需要管理员权限） |
| 404 | Not Found | 资源不存在 |
| 500 | Internal Server Error | 服务器内部错误 |

### 错误响应格式

```json
{
  "error": "错误信息"
}
```

### 常见错误信息

| error 字段 | 状态码 | 描述 |
|------------|--------|------|
| Unauthorized | 401 | 未登录或 Cookie 无效 |
| 用户不存在 | 401 | 用户账户不存在 |
| 用户已被封禁 | 401 | 用户已被禁用 |
| Forbidden: Admin only | 403 | 需要管理员权限 |
| 缺少必要参数 | 400 | 必需的参数缺失 |
| Invalid key format | 400 | key 参数格式错误 |
| Internal Server Error | 500 | 服务器内部错误 |

---

## 注意事项

1. **认证**：大部分 API 需要用户登录后才能访问，请在调用前确保用户已登录
2. **速率限制**：系统可能对 API 请求频率进行限制，请合理控制请求频率
3. **缓存**：部分 API 响应会被缓存，缓存时间由系统配置决定
4. **安全性**：请勿在客户端存储敏感信息，如密码等
5. **存储模式**：部分功能（如注册、修改密码）在 localStorage 模式下不可用
6. **CORS**：API 支持跨域请求，已配置相应的 CORS 头

---

## 数据结构

### Favorite（收藏）

```typescript
interface Favorite {
  title: string;           // 视频标题
  poster?: string;         // 海报 URL
  year?: string;           // 年份
  type_name?: string;      // 类型名称
  source_name: string;     // 来源名称
  save_time?: number;      // 保存时间戳
}
```

### PlayRecord（播放记录）

```typescript
interface PlayRecord {
  title: string;           // 视频标题
  source_name: string;     // 来源名称
  index: number;           // 当前集数
  play_time: number;      // 当前播放时间（秒）
  total_time: number;      // 总播放时间（秒）
  total_episodes: number;  // 总集数
  original_episodes?: number;  // 原始总集数
  save_time?: number;     // 保存时间戳
}
```

### DoubanItem（豆瓣条目）

```typescript
interface DoubanItem {
  id: string;              // 豆瓣 ID
  title: string;           // 标题
  poster: string;          // 海报 URL
  rate: string;           // 评分
  year: string;           // 年份
}
```

---

## 版本信息

- API 版本：1.0.0
- 系统版本：由 `process.env.NEXT_PUBLIC_APP_VERSION` 定义

---

## 联系与支持

如有 API 使用问题，请联系系统管理员或查看项目文档。