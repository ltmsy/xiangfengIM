-- IM系统数据库表结构设计
-- 基于功能清单V1基础版设计
-- 悟空IM集成架构设计
--
-- 设计理念：
-- 1. 业务表不重复存储悟空IM已存储的数据（如消息内容、会话信息）
-- 2. 通过映射字段关联悟空IM的频道、消息、用户等
-- 3. 业务表专注于悟空IM不支持的扩展功能（置顶、免打扰、收藏、标签等）
-- 4. 悟空IM负责消息传输、存储、实时通信、会话管理等核心功能
-- 5. 通过Webhook事件通知实现业务逻辑处理
-- 6. 采用轻量级架构，避免数据重复，提升性能和可维护性

-- 创建数据库
CREATE DATABASE IF NOT EXISTS im_system DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE im_system;

-- 1. 用户表（映射悟空IM用户）
CREATE TABLE `users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `uid` varchar(64) NOT NULL COMMENT '用户唯一标识',
  `wukongim_uid` varchar(64) NOT NULL COMMENT '悟空IM用户UID',
  `username` varchar(50) NOT NULL COMMENT '用户名',
  `password` varchar(255) NOT NULL COMMENT '密码（加密）',
  `nickname` varchar(100) DEFAULT NULL COMMENT '昵称',
  `avatar` varchar(500) DEFAULT NULL COMMENT '头像URL',
  `signature` varchar(500) DEFAULT NULL COMMENT '个性签名',
  `email` varchar(100) DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态：1-正常，2-禁用，3-删除',
  `last_login_time` datetime DEFAULT NULL COMMENT '最后登录时间',
  `last_active_time` datetime DEFAULT NULL COMMENT '最后活跃时间',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uid` (`uid`),
  UNIQUE KEY `uk_wukongim_uid` (`wukongim_uid`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_status` (`status`),
  KEY `idx_last_active` (`last_active_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表（映射悟空IM用户）';

-- 2. 用户设备表（映射悟空IM连接）
CREATE TABLE `user_devices` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '设备ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `wukongim_uid` varchar(64) NOT NULL COMMENT '悟空IM用户UID',
  `device_id` varchar(128) NOT NULL COMMENT '设备唯一标识',
  `device_type` tinyint(1) NOT NULL COMMENT '设备类型：1-PC网页，2-PC桌面，3-移动APP',
  `device_name` varchar(100) DEFAULT NULL COMMENT '设备名称',
  `device_info` text COMMENT '设备详细信息',
  `login_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '登录时间',
  `last_active_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '最后活跃时间',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态：1-在线，2-离线，3-强制下线',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_device` (`user_id`, `device_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_wukongim_uid` (`wukongim_uid`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户设备表（映射悟空IM连接）';

-- 3. 好友关系表
CREATE TABLE `friendships` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '关系ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `friend_id` bigint(20) NOT NULL COMMENT '好友ID',
  `remark` varchar(100) DEFAULT NULL COMMENT '备注名',
  `group_id` bigint(20) DEFAULT NULL COMMENT '分组ID',
  `is_star` tinyint(1) DEFAULT 0 COMMENT '是否星标：0-否，1-是',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态：1-正常，2-删除',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_friend` (`user_id`, `friend_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_friend_id` (`friend_id`),
  KEY `idx_group_id` (`group_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`friend_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='好友关系表';

-- 4. 好友分组表
CREATE TABLE `friend_groups` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分组ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `name` varchar(50) NOT NULL COMMENT '分组名称',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序顺序',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='好友分组表';

-- 5. 好友申请记录表
CREATE TABLE `friend_requests` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '申请ID',
  `from_user_id` bigint(20) NOT NULL COMMENT '申请用户ID',
  `to_user_id` bigint(20) NOT NULL COMMENT '接收用户ID',
  `message` varchar(500) DEFAULT NULL COMMENT '申请消息',
  `status` tinyint(1) DEFAULT 0 COMMENT '状态：0-待处理，1-同意，2-拒绝，3-忽略',
  `handle_time` datetime DEFAULT NULL COMMENT '处理时间',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_from_user` (`from_user_id`),
  KEY `idx_to_user` (`to_user_id`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`from_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`to_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='好友申请记录表';

-- 6. 黑名单表
CREATE TABLE `blacklist` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '黑名单ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `blocked_user_id` bigint(20) NOT NULL COMMENT '被拉黑用户ID',
  `reason` varchar(500) DEFAULT NULL COMMENT '拉黑原因',
  `block_type` tinyint(1) DEFAULT 1 COMMENT '拉黑类型：1-消息，2-加好友，3-查看资料，4-全部',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '拉黑时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_blocked` (`user_id`, `blocked_user_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_blocked_user` (`blocked_user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`blocked_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='黑名单表';

-- 7. 群组表（映射悟空IM群聊频道）
CREATE TABLE `groups` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '群组ID',
  `group_id` varchar(64) NOT NULL COMMENT '群组唯一标识',
  `wukongim_channel_id` varchar(128) NOT NULL COMMENT '悟空IM群聊频道ID',
  `name` varchar(100) NOT NULL COMMENT '群组名称',
  `avatar` varchar(500) DEFAULT NULL COMMENT '群组头像',
  `description` varchar(500) DEFAULT NULL COMMENT '群组描述',
  `announcement` text COMMENT '群组公告',
  `owner_id` bigint(20) NOT NULL COMMENT '群主ID',
  `max_members` int(11) DEFAULT 200 COMMENT '最大成员数',
  `current_members` int(11) DEFAULT 1 COMMENT '当前成员数',
  `invite_type` tinyint(1) DEFAULT 1 COMMENT '邀请方式：1-自由加入，2-需验证，3-仅邀请',
  `history_visible` tinyint(1) DEFAULT 1 COMMENT '历史消息可见：1-不可见，2-可见部分，3-全部可见',
  `history_days` int(11) DEFAULT 0 COMMENT '历史消息可见天数（0表示全部）',
  `allow_edit_msg` tinyint(1) DEFAULT 1 COMMENT '是否允许编辑消息：0-否，1-是',
  `allow_withdraw_msg` tinyint(1) DEFAULT 1 COMMENT '是否允许撤回消息：0-否，1-是',
  `withdraw_time_limit` int(11) DEFAULT 300 COMMENT '撤回时间限制（秒）',
  `allow_add_friend` tinyint(1) DEFAULT 1 COMMENT '是否允许从群内加好友：0-否，1-需验证，2-允许',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态：1-正常，2-解散',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_id` (`group_id`),
  UNIQUE KEY `uk_wukongim_channel` (`wukongim_channel_id`),
  KEY `idx_owner_id` (`owner_id`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='群组表（映射悟空IM群聊频道）';

-- 8. 群组成员表（映射悟空IM频道订阅者）
CREATE TABLE `group_members` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '成员ID',
  `group_id` bigint(20) NOT NULL COMMENT '群组ID',
  `wukongim_channel_id` varchar(128) NOT NULL COMMENT '悟空IM频道ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `wukongim_uid` varchar(64) NOT NULL COMMENT '悟空IM用户UID',
  `nickname` varchar(100) DEFAULT NULL COMMENT '群昵称',
  `role` tinyint(1) DEFAULT 0 COMMENT '角色：0-普通成员，1-管理员，2-群主',
  `join_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `last_speak_time` datetime DEFAULT NULL COMMENT '最后发言时间',
  `is_muted` tinyint(1) DEFAULT 0 COMMENT '是否禁言：0-否，1-是',
  `mute_until` datetime DEFAULT NULL COMMENT '禁言截止时间',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态：1-正常，2-退出',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_user` (`group_id`, `user_id`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_wukongim_channel_id` (`wukongim_channel_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_wukongim_uid` (`wukongim_uid`),
  KEY `idx_role` (`role`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='群组成员表（映射悟空IM频道订阅者）';

-- 9. 群组邀请记录表
CREATE TABLE `group_invitations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '邀请ID',
  `group_id` bigint(20) NOT NULL COMMENT '群组ID',
  `inviter_id` bigint(20) NOT NULL COMMENT '邀请人ID',
  `invitee_id` bigint(20) NOT NULL COMMENT '被邀请人ID',
  `message` varchar(500) DEFAULT NULL COMMENT '邀请消息',
  `status` tinyint(1) DEFAULT 0 COMMENT '状态：0-待处理，1-同意，2-拒绝',
  `handle_time` datetime DEFAULT NULL COMMENT '处理时间',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '邀请时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_inviter_id` (`inviter_id`),
  KEY `idx_invitee_id` (`invitee_id`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`inviter_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`invitee_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='群组邀请记录表';

-- 10. 用户会话设置表（悟空IM会话扩展功能）
CREATE TABLE `user_conversation_settings` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '设置ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `wukongim_channel_id` varchar(128) NOT NULL COMMENT '悟空IM频道ID',
  `is_top` tinyint(1) DEFAULT 0 COMMENT '是否置顶：0-否，1-是',
  `is_muted` tinyint(1) DEFAULT 0 COMMENT '是否免打扰：0-否，1-是',
  `mute_type` tinyint(1) DEFAULT 0 COMMENT '免打扰类型：0-全部，1-仅消息，2-仅@我',
  `draft` text COMMENT '草稿内容',
  `sort_order` int(11) DEFAULT 0 COMMENT '自定义排序顺序',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_channel` (`user_id`, `wukongim_channel_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_wukongim_channel_id` (`wukongim_channel_id`),
  KEY `idx_is_top` (`is_top`),
  KEY `idx_sort_order` (`sort_order`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户会话设置表（悟空IM会话扩展功能）';

-- 11. 业务消息扩展表（悟空IM消息扩展功能）
CREATE TABLE `business_message_extensions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '扩展ID',
  `wukongim_message_id` varchar(64) NOT NULL COMMENT '悟空IM消息ID',
  `wukongim_channel_id` varchar(128) NOT NULL COMMENT '悟空IM频道ID',
  `sender_id` varchar(64) NOT NULL COMMENT '发送者ID',
  `message_type` tinyint(1) NOT NULL COMMENT '消息类型：1-文本，2-图片，3-文件，4-音频，5-视频，6-位置，7-名片，8-链接，9-代码，10-表情',
  `is_pinned` tinyint(1) DEFAULT 0 COMMENT '是否置顶：0-否，1-是',
  `pin_time` datetime DEFAULT NULL COMMENT '置顶时间',
  `pin_user_id` varchar(64) DEFAULT NULL COMMENT '置顶用户ID',
  `business_tags` json COMMENT '业务标签',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_wukongim_message` (`wukongim_message_id`),
  KEY `idx_wukongim_channel_id` (`wukongim_channel_id`),
  KEY `idx_sender_id` (`sender_id`),
  KEY `idx_message_type` (`message_type`),
  KEY `idx_is_pinned` (`is_pinned`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='业务消息扩展表（悟空IM消息扩展功能）';

-- 12. 消息状态表（悟空IM消息状态映射）
CREATE TABLE `message_status` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '状态ID',
  `wukongim_message_id` varchar(64) NOT NULL COMMENT '悟空IM消息ID',
  `user_id` varchar(64) NOT NULL COMMENT '用户ID',
  `is_read` tinyint(1) DEFAULT 0 COMMENT '是否已读：0-否，1-是',
  `read_time` datetime DEFAULT NULL COMMENT '已读时间',
  `is_delivered` tinyint(1) DEFAULT 0 COMMENT '是否已送达：0-否，1-是',
  `deliver_time` datetime DEFAULT NULL COMMENT '送达时间',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_message_user` (`wukongim_message_id`, `user_id`),
  KEY `idx_wukongim_message_id` (`wukongim_message_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_is_read` (`is_read`),
  KEY `idx_is_delivered` (`is_delivered`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息状态表（悟空IM消息状态映射）';

-- 13. 收藏表（悟空IM消息收藏）
CREATE TABLE `favorites` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '收藏ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `wukongim_message_id` varchar(64) NOT NULL COMMENT '悟空IM消息ID',
  `wukongim_channel_id` varchar(128) NOT NULL COMMENT '悟空IM频道ID',
  `favorite_type` tinyint(1) NOT NULL COMMENT '收藏类型：1-消息，2-图片，3-文件，4-链接，5-代码片段',
  `content_summary` varchar(500) COMMENT '收藏内容摘要',
  `file_url` varchar(500) DEFAULT NULL COMMENT '文件URL',
  `file_name` varchar(255) DEFAULT NULL COMMENT '文件名',
  `file_size` bigint(20) DEFAULT NULL COMMENT '文件大小',
  `thumbnail_url` varchar(500) DEFAULT NULL COMMENT '缩略图URL',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_message` (`user_id`, `wukongim_message_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_wukongim_message_id` (`wukongim_message_id`),
  KEY `idx_wukongim_channel_id` (`wukongim_channel_id`),
  KEY `idx_favorite_type` (`favorite_type`),
  KEY `idx_created_at` (`created_at`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收藏表（悟空IM消息收藏）';

-- 14. 系统配置表
CREATE TABLE `system_configs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '配置ID',
  `config_key` varchar(100) NOT NULL COMMENT '配置键',
  `config_value` text COMMENT '配置值',
  `config_type` varchar(50) DEFAULT 'string' COMMENT '配置类型',
  `description` varchar(500) DEFAULT NULL COMMENT '配置描述',
  `is_public` tinyint(1) DEFAULT 0 COMMENT '是否公开：0-否，1-是',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`),
  KEY `idx_is_public` (`is_public`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置表';

-- 15. 用户设置表
CREATE TABLE `user_settings` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '设置ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `setting_key` varchar(100) NOT NULL COMMENT '设置键',
  `setting_value` text COMMENT '设置值',
  `setting_type` varchar(50) DEFAULT 'string' COMMENT '设置类型',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_setting` (`user_id`, `setting_key`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_setting_key` (`setting_key`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户设置表';

-- 16. 操作日志表
CREATE TABLE `operation_logs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户ID',
  `operation_type` varchar(100) NOT NULL COMMENT '操作类型',
  `operation_desc` varchar(500) DEFAULT NULL COMMENT '操作描述',
  `target_type` varchar(50) DEFAULT NULL COMMENT '目标类型',
  `target_id` varchar(64) DEFAULT NULL COMMENT '目标ID',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'IP地址',
  `user_agent` text COMMENT '用户代理',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_operation_type` (`operation_type`),
  KEY `idx_target_type` (`target_type`),
  KEY `idx_created_at` (`created_at`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作日志表';

-- 17. 敏感词表
CREATE TABLE `sensitive_words` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '敏感词ID',
  `word` varchar(100) NOT NULL COMMENT '敏感词',
  `word_type` tinyint(1) DEFAULT 1 COMMENT '敏感词类型：1-政治，2-色情，3-暴力，4-其他',
  `action_type` tinyint(1) DEFAULT 1 COMMENT '处理方式：1-拦截，2-提醒，3-替换',
  `replace_word` varchar(100) DEFAULT NULL COMMENT '替换词',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态：1-启用，2-禁用',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_word` (`word`),
  KEY `idx_word_type` (`word_type`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='敏感词表';

-- 18. 文件记录表（悟空IM文件消息关联）
CREATE TABLE `file_records` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '文件ID',
  `file_id` varchar(64) NOT NULL COMMENT '文件唯一标识',
  `file_name` varchar(255) NOT NULL COMMENT '文件名',
  `file_path` varchar(500) NOT NULL COMMENT '文件路径',
  `file_url` varchar(500) NOT NULL COMMENT '文件URL',
  `file_size` bigint(20) NOT NULL COMMENT '文件大小（字节）',
  `file_type` varchar(100) DEFAULT NULL COMMENT '文件类型',
  `mime_type` varchar(100) DEFAULT NULL COMMENT 'MIME类型',
  `file_hash` varchar(64) DEFAULT NULL COMMENT '文件哈希值',
  `upload_user_id` bigint(20) NOT NULL COMMENT '上传用户ID',
  `wukongim_channel_id` varchar(128) DEFAULT NULL COMMENT '悟空IM频道ID',
  `wukongim_message_id` varchar(64) DEFAULT NULL COMMENT '悟空IM消息ID',
  `download_count` int(11) DEFAULT 0 COMMENT '下载次数',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态：1-正常，2-删除',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_file_id` (`file_id`),
  KEY `idx_upload_user` (`upload_user_id`),
  KEY `idx_wukongim_channel_id` (`wukongim_channel_id`),
  KEY `idx_wukongim_message_id` (`wukongim_message_id`),
  KEY `idx_file_type` (`file_type`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  FOREIGN KEY (`upload_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文件记录表（悟空IM文件消息关联）';

-- 19. 群组置顶消息表（悟空IM消息置顶）
CREATE TABLE `group_pinned_messages` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '置顶ID',
  `group_id` bigint(20) NOT NULL COMMENT '群组ID',
  `wukongim_message_id` varchar(64) NOT NULL COMMENT '悟空IM消息ID',
  `wukongim_channel_id` varchar(128) NOT NULL COMMENT '悟空IM频道ID',
  `pin_user_id` bigint(20) NOT NULL COMMENT '置顶用户ID',
  `pin_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '置顶时间',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序顺序',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态：1-正常，2-取消置顶',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_message` (`group_id`, `wukongim_message_id`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_wukongim_message_id` (`wukongim_message_id`),
  KEY `idx_wukongim_channel_id` (`wukongim_channel_id`),
  KEY `idx_pin_user` (`pin_user_id`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='群组置顶消息表（悟空IM消息置顶）';

-- 20. 用户隐私设置表
CREATE TABLE `user_privacy_settings` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '设置ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `allow_friend_request` tinyint(1) DEFAULT 1 COMMENT '是否允许好友申请：0-仅好友，1-所有人',
  `auto_create_conversation` tinyint(1) DEFAULT 1 COMMENT '是否允许自动建会话：0-否，1-是',
  `allow_group_add_friend` tinyint(1) DEFAULT 1 COMMENT '是否允许从群内加好友：0-禁止，1-需验证，2-允许',
  `allow_send_file` tinyint(1) DEFAULT 1 COMMENT '是否允许接收文件：0-否，1-是',
  `file_size_limit` bigint(20) DEFAULT 104857600 COMMENT '文件大小限制（字节）',
  `allowed_file_types` text COMMENT '允许的文件类型',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户隐私设置表';

-- 21. 悟空IM事件通知表
CREATE TABLE `wukongim_events` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '事件ID',
  `event_id` varchar(64) NOT NULL COMMENT '事件唯一标识',
  `event_type` varchar(100) NOT NULL COMMENT '事件类型',
  `event_data` json COMMENT '事件数据（JSON格式）',
  `channel_id` varchar(128) DEFAULT NULL COMMENT '相关频道ID',
  `message_id` varchar(64) DEFAULT NULL COMMENT '相关消息ID',
  `user_id` varchar(64) DEFAULT NULL COMMENT '相关用户ID',
  `status` tinyint(1) DEFAULT 0 COMMENT '处理状态：0-待处理，1-处理中，2-处理完成，3-处理失败',
  `process_time` datetime DEFAULT NULL COMMENT '处理时间',
  `error_message` text COMMENT '错误信息',
  `retry_count` int(11) DEFAULT 0 COMMENT '重试次数',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '事件接收时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_event_id` (`event_id`),
  KEY `idx_event_type` (`event_type`),
  KEY `idx_channel_id` (`channel_id`),
  KEY `idx_message_id` (`message_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='悟空IM事件通知表';

-- 插入默认数据
INSERT INTO `friend_groups` (`user_id`, `name`, `sort_order`) VALUES 
(1, '默认分组', 1),
(1, '星标好友', 2);

INSERT INTO `system_configs` (`config_key`, `config_value`, `config_type`, `description`, `is_public`) VALUES
('max_file_size', '104857600', 'number', '最大文件上传大小（字节）', 1),
('allowed_file_types', 'jpg,jpeg,png,gif,pdf,doc,docx,xls,xlsx,ppt,pptx,txt,zip,rar', 'string', '允许上传的文件类型', 1),
('message_withdraw_time_limit', '300', 'number', '消息撤回时间限制（秒）', 1),
('max_group_members', '200', 'number', '群组最大成员数', 1),
('sensitive_word_action', '1', 'number', '敏感词处理方式：1-拦截，2-提醒，3-替换', 1);

-- 创建索引优化查询性能
CREATE INDEX idx_user_conversation_settings_user ON user_conversation_settings(user_id);
CREATE INDEX idx_user_conversation_settings_channel ON user_conversation_settings(wukongim_channel_id);
CREATE INDEX idx_user_conversation_settings_top ON user_conversation_settings(is_top);
CREATE INDEX idx_user_conversation_settings_sort ON user_conversation_settings(sort_order);

CREATE INDEX idx_business_message_extensions_channel ON business_message_extensions(wukongim_channel_id);
CREATE INDEX idx_business_message_extensions_sender ON business_message_extensions(sender_id);
CREATE INDEX idx_business_message_extensions_pinned ON business_message_extensions(is_pinned);

CREATE INDEX idx_message_status_user ON message_status(user_id);
CREATE INDEX idx_message_status_read ON message_status(is_read);
CREATE INDEX idx_message_status_delivered ON message_status(is_delivered);

CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_message ON favorites(wukongim_message_id);
CREATE INDEX idx_favorites_channel ON favorites(wukongim_channel_id);
CREATE INDEX idx_favorites_type ON favorites(favorite_type);

CREATE INDEX idx_friendships_user_status ON friendships(user_id, status);
CREATE INDEX idx_group_members_group_role ON group_members(group_id, role);
CREATE INDEX idx_group_members_wukongim_channel ON group_members(wukongim_channel_id);
CREATE INDEX idx_group_members_wukongim_uid ON group_members(wukongim_uid);

CREATE INDEX idx_blacklist_user_blocked ON blacklist(user_id, blocked_user_id);
CREATE INDEX idx_file_records_user_time ON file_records(upload_user_id, created_at DESC);
CREATE INDEX idx_file_records_channel ON file_records(wukongim_channel_id);
CREATE INDEX idx_file_records_message ON file_records(wukongim_message_id);

CREATE INDEX idx_group_pinned_messages_group ON group_pinned_messages(group_id);
CREATE INDEX idx_group_pinned_messages_message ON group_pinned_messages(wukongim_message_id);
CREATE INDEX idx_group_pinned_messages_channel ON group_pinned_messages(wukongim_channel_id);

CREATE INDEX idx_users_wukongim_uid ON users(wukongim_uid);
CREATE INDEX idx_user_devices_wukongim_uid ON user_devices(wukongim_uid);

CREATE INDEX idx_wukongim_events_type_status ON wukongim_events(event_type, status);
CREATE INDEX idx_wukongim_events_channel ON wukongim_events(channel_id);
CREATE INDEX idx_wukongim_events_user ON wukongim_events(user_id);
