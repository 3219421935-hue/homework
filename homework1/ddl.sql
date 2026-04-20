-- =============================================
-- 淘宝电商平台数据库DDL脚本
-- 生成日期: 2026-04-20
-- 数据库: MySQL 8.0+
-- 字符集: utf8mb4
-- =============================================

-- 设置字符集
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =============================================
-- 1. 用户表 (user)
-- =============================================
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
    `user_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户唯一标识',
    `username` VARCHAR(50) NOT NULL COMMENT '用户昵称',
    `password_hash` VARCHAR(255) NOT NULL COMMENT '加密存储密码',
    `email` VARCHAR(100) NOT NULL COMMENT '邮箱地址',
    `phone` CHAR(11) DEFAULT NULL COMMENT '手机号码',
    `register_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    `last_login` DATETIME DEFAULT NULL COMMENT '最后登录时间',
    `role_type` TINYINT NOT NULL DEFAULT 0 COMMENT '角色类型：0-普通用户, 1-商家, 2-管理员',
    `status` ENUM('active','frozen','deleted') NOT NULL DEFAULT 'active' COMMENT '账户状态',
    PRIMARY KEY (`user_id`),
    UNIQUE KEY `uk_username` (`username`),
    UNIQUE KEY `uk_email` (`email`),
    KEY `idx_role_type` (`role_type`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- =============================================
-- 2. 店铺表 (shop)
-- =============================================
DROP TABLE IF EXISTS `shop`;
CREATE TABLE `shop` (
    `shop_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '店铺唯一标识',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '关联店主用户ID',
    `shop_name` VARCHAR(100) NOT NULL COMMENT '店铺名称',
    `business_scope` VARCHAR(200) DEFAULT NULL COMMENT '经营范围',
    `contact_phone` VARCHAR(20) DEFAULT NULL COMMENT '联系电话',
    `shop_status` TINYINT NOT NULL DEFAULT 1 COMMENT '营业状态：0-关闭, 1-营业',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `rating` DECIMAL(3,2) DEFAULT NULL COMMENT '商家综合评分',
    PRIMARY KEY (`shop_id`),
    UNIQUE KEY `uk_shop_name` (`shop_name`),
    UNIQUE KEY `uk_owner_id` (`owner_id`),
    KEY `idx_shop_status` (`shop_status`),
    CONSTRAINT `fk_shop_user` FOREIGN KEY (`owner_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='店铺表';

-- =============================================
-- 3. 购物车表 (cart)
-- =============================================
DROP TABLE IF EXISTS `cart`;
CREATE TABLE `cart` (
    `cart_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '购物车主键',
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT '所属用户ID',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
    PRIMARY KEY (`cart_id`),
    UNIQUE KEY `uk_user_id` (`user_id`),
    CONSTRAINT `fk_cart_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='购物车表';

-- =============================================
-- 4. 商品类别表 (category)
-- =============================================
DROP TABLE IF EXISTS `category`;
CREATE TABLE `category` (
    `category_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '分类ID',
    `parent_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '父分类ID，顶级为0',
    `category_name` VARCHAR(50) NOT NULL COMMENT '分类名称',
    `level` TINYINT UNSIGNED NOT NULL COMMENT '层级深度（1=一级类目）',
    `sort_order` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '排序权重',
    `category_status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0-禁用, 1-启用',
    `path` VARCHAR(255) DEFAULT NULL COMMENT '全路径枚举（如 /1/3/15/）',
    PRIMARY KEY (`category_id`),
    KEY `idx_parent_id` (`parent_id`),
    KEY `idx_level` (`level`),
    KEY `idx_category_status` (`category_status`),
    KEY `idx_parent_sort` (`parent_id`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品类别表';

-- 添加自引用外键约束（表创建后添加）
ALTER TABLE `category` 
    ADD CONSTRAINT `fk_category_parent` 
    FOREIGN KEY (`parent_id`) REFERENCES `category` (`category_id`) 
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- =============================================
-- 5. SPU表（标准产品单元）(spu)
-- =============================================
DROP TABLE IF EXISTS `spu`;
CREATE TABLE `spu` (
    `spu_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'SPU主键',
    `shop_id` INT UNSIGNED NOT NULL COMMENT '所属店铺ID',
    `category_id` BIGINT UNSIGNED NOT NULL COMMENT '商品分类',
    `brand_name` VARCHAR(50) DEFAULT NULL COMMENT '品牌名称',
    `spu_name` VARCHAR(200) NOT NULL COMMENT '商品名称',
    `selling_point` TEXT DEFAULT NULL COMMENT '卖点描述',
    `main_image` VARCHAR(500) DEFAULT NULL COMMENT '主图URL',
    `spu_status` TINYINT NOT NULL DEFAULT 1 COMMENT '上架状态：0-下架, 1-上架, 2-售罄',
    `sale_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总销量',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`spu_id`),
    KEY `idx_shop_id` (`shop_id`),
    KEY `idx_category_id` (`category_id`),
    KEY `idx_spu_status` (`spu_status`),
    CONSTRAINT `fk_spu_shop` FOREIGN KEY (`shop_id`) REFERENCES `shop` (`shop_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_spu_category` FOREIGN KEY (`category_id`) REFERENCES `category` (`category_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SPU表（标准产品单元）';

-- =============================================
-- 6. SKU表（库存单位）(sku)
-- =============================================
DROP TABLE IF EXISTS `sku`;
CREATE TABLE `sku` (
    `sku_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'SKU主键',
    `spu_id` BIGINT UNSIGNED NOT NULL COMMENT '所属SPU ID',
    `sku_code` VARCHAR(50) DEFAULT NULL COMMENT '仓储编码',
    `price` DECIMAL(10,2) NOT NULL COMMENT '销售价（单位：元）',
    `cost_price` DECIMAL(10,2) DEFAULT NULL COMMENT '成本价',
    `stock` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '可售库存',
    `lock_stock` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '已锁定库存（防超卖）',
    `spec_attributes` JSON NOT NULL COMMENT '规格属性：{"颜色":"黑色","尺码":"XL"}',
    `is_default` TINYINT NOT NULL DEFAULT 0 COMMENT '是否默认SKU',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`sku_id`),
    UNIQUE KEY `uk_sku_code` (`sku_code`),
    KEY `idx_spu_id` (`spu_id`),
    KEY `idx_price` (`price`),
    CONSTRAINT `fk_sku_spu` FOREIGN KEY (`spu_id`) REFERENCES `spu` (`spu_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SKU表（库存单位）';

-- =============================================
-- 7. 订单表 (`order`)
-- =============================================
DROP TABLE IF EXISTS `order`;
CREATE TABLE `order` (
    `order_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '内部订单ID',
    `order_no` VARCHAR(32) NOT NULL COMMENT '业务订单号，非连续生成',
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT '下单用户ID',
    `total_amount` DECIMAL(12,2) NOT NULL COMMENT '订单总金额',
    `pay_amount` DECIMAL(12,2) NOT NULL COMMENT '实际支付金额',
    `freight_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '运费',
    `discount_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '优惠抵扣',
    `order_status` TINYINT NOT NULL COMMENT '状态码：1待支付,2已支付,3已发货,4已完成,5已取消',
    `payment_status` TINYINT NOT NULL DEFAULT 0 COMMENT '支付状态：0未支付,1已支付,2已退款',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '下单时间',
    `pay_time` DATETIME DEFAULT NULL COMMENT '支付完成时间',
    `delivery_time` DATETIME DEFAULT NULL COMMENT '发货时间',
    `receive_time` DATETIME DEFAULT NULL COMMENT '签收时间',
    `receiver_name` VARCHAR(20) NOT NULL COMMENT '收货人姓名（快照）',
    `receiver_phone` CHAR(11) NOT NULL COMMENT '收货电话（快照）',
    `receiver_address` VARCHAR(300) NOT NULL COMMENT '完整地址（快照）',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
    PRIMARY KEY (`order_id`),
    UNIQUE KEY `uk_order_no` (`order_no`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_order_status` (`order_status`),
    KEY `idx_payment_status` (`payment_status`),
    KEY `idx_create_time` (`create_time`),
    CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单表';

-- =============================================
-- 8. 订单项表 (order_item)
-- =============================================
DROP TABLE IF EXISTS `order_item`;
CREATE TABLE `order_item` (
    `item_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '订单项ID',
    `order_id` BIGINT UNSIGNED NOT NULL COMMENT '所属订单ID',
    `sku_id` BIGINT UNSIGNED NOT NULL COMMENT '购买的SKU ID',
    `product_name` VARCHAR(255) NOT NULL COMMENT '商品名称快照',
    `price` DECIMAL(10,2) NOT NULL COMMENT '购买单价快照',
    `quantity` INT UNSIGNED NOT NULL COMMENT '购买数量',
    `subtotal` DECIMAL(10,2) NOT NULL AS (price * quantity) STORED COMMENT '小计金额（计算列）',
    `spec_attr` VARCHAR(200) DEFAULT NULL COMMENT '规格属性快照（如"颜色:黑,内存:128G"）',
    `image_url` VARCHAR(500) DEFAULT NULL COMMENT '商品图片快照',
    PRIMARY KEY (`item_id`),
    KEY `idx_order_id` (`order_id`),
    KEY `idx_sku_id` (`sku_id`),
    CONSTRAINT `fk_order_item_order` FOREIGN KEY (`order_id`) REFERENCES `order` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_order_item_sku` FOREIGN KEY (`sku_id`) REFERENCES `sku` (`sku_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_quantity` CHECK (`quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单项表';

-- =============================================
-- 9. 购物车项表 (cart_item)
-- =============================================
DROP TABLE IF EXISTS `cart_item`;
CREATE TABLE `cart_item` (
    `cart_item_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '购物车项ID',
    `cart_id` BIGINT UNSIGNED NOT NULL COMMENT '所属购物车ID',
    `sku_id` BIGINT UNSIGNED NOT NULL COMMENT '添加的SKU ID',
    `quantity` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '数量',
    `price` DECIMAL(10,2) NOT NULL COMMENT '当前价格快照',
    `added_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
    `checked` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否选中结算',
    `valid` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否有效（未下架）',
    PRIMARY KEY (`cart_item_id`),
    UNIQUE KEY `uk_cart_sku` (`cart_id`, `sku_id`),
    KEY `idx_sku_id` (`sku_id`),
    CONSTRAINT `fk_cart_item_cart` FOREIGN KEY (`cart_id`) REFERENCES `cart` (`cart_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cart_item_sku` FOREIGN KEY (`sku_id`) REFERENCES `sku` (`sku_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='购物车项表';

-- =============================================
-- 10. 评论表 (review)
-- =============================================
DROP TABLE IF EXISTS `review`;
CREATE TABLE `review` (
    `review_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '评论ID',
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT '评论者ID',
    `sku_id` BIGINT UNSIGNED NOT NULL COMMENT '被评商品SKU',
    `order_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '关联订单（可选）',
    `rating` TINYINT NOT NULL COMMENT '评分（1~5星）',
    `comment` TEXT DEFAULT NULL COMMENT '评论内容',
    `parent_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '回复父评论ID（递归结构）',
    `status` ENUM('pending','approved','rejected') NOT NULL DEFAULT 'approved' COMMENT '审核状态',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`review_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_sku_id` (`sku_id`),
    KEY `idx_order_id` (`order_id`),
    KEY `idx_parent_id` (`parent_id`),
    KEY `idx_status` (`status`),
    CONSTRAINT `fk_review_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_review_sku` FOREIGN KEY (`sku_id`) REFERENCES `sku` (`sku_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_review_order` FOREIGN KEY (`order_id`) REFERENCES `order` (`order_id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `chk_rating` CHECK (`rating` BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评论表';

-- 添加自引用外键约束（表创建后添加）
ALTER TABLE `review` 
    ADD CONSTRAINT `fk_review_parent` 
    FOREIGN KEY (`parent_id`) REFERENCES `review` (`review_id`) 
    ON DELETE CASCADE ON UPDATE CASCADE;

-- =============================================
-- 11. 支付表 (payment)
-- =============================================
DROP TABLE IF EXISTS `payment`;
CREATE TABLE `payment` (
    `payment_id` VARCHAR(32) NOT NULL COMMENT '支付单号（如 PAY20241011XXXX）',
    `order_id` VARCHAR(32) NOT NULL COMMENT '关联业务订单号',
    `amount` INT NOT NULL COMMENT '支付金额（单位：分）',
    `pay_type` VARCHAR(20) NOT NULL COMMENT '支付方式：alipay, wechat_pay 等',
    `status` VARCHAR(20) NOT NULL COMMENT '状态：INIT, PAID, FAILED',
    `third_party_trade_no` VARCHAR(64) DEFAULT NULL COMMENT '第三方支付流水号（幂等键）',
    `paid_at` DATETIME DEFAULT NULL COMMENT '实际支付时间',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`payment_id`),
    UNIQUE KEY `uk_third_party_trade_no` (`third_party_trade_no`),
    KEY `idx_order_id` (`order_id`),
    KEY `idx_status` (`status`),
    CONSTRAINT `fk_payment_order` FOREIGN KEY (`order_id`) REFERENCES `order` (`order_no`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付表';

-- =============================================
-- 12. 物流表 (logistics)
-- =============================================
DROP TABLE IF EXISTS `logistics`;
CREATE TABLE `logistics` (
    `logistics_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '物流记录ID',
    `order_id` BIGINT UNSIGNED NOT NULL COMMENT '关联订单',
    `courier_company` VARCHAR(100) DEFAULT NULL COMMENT '快递公司名称',
    `tracking_number` VARCHAR(50) DEFAULT NULL COMMENT '快递单号',
    `shipment_time` DATETIME DEFAULT NULL COMMENT '发货时间',
    `estimated_arrival` DATETIME DEFAULT NULL COMMENT '预计送达时间',
    `status` TINYINT NOT NULL COMMENT '状态：0待发货,1已发货,2运输中,3派送中,4已签收,5异常,6退回',
    `signed_time` DATETIME DEFAULT NULL COMMENT '实际签收时间',
    `signer` VARCHAR(50) DEFAULT NULL COMMENT '签收人',
    `remarks` VARCHAR(255) DEFAULT NULL COMMENT '配送备注',
    PRIMARY KEY (`logistics_id`),
    UNIQUE KEY `uk_tracking_number` (`tracking_number`),
    KEY `idx_order_id` (`order_id`),
    KEY `idx_status` (`status`),
    CONSTRAINT `fk_logistics_order` FOREIGN KEY (`order_id`) REFERENCES `order` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='物流表';

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================
-- 测试数据插入
-- =============================================

-- 插入用户测试数据
INSERT INTO `user` (`user_id`, `username`, `password_hash`, `email`, `phone`, `role_type`, `status`) VALUES
(1, 'zhangsan', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'zhangsan@example.com', '13800138001', 1, 'active'),
(2, 'lisi_buyer', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'lisi@example.com', '13800138002', 0, 'active'),
(3, 'wangwu_buyer', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'wangwu@example.com', '13800138003', 0, 'active');

-- 插入店铺测试数据
INSERT INTO `shop` (`shop_id`, `owner_id`, `shop_name`, `business_scope`, `contact_phone`, `shop_status`, `rating`) VALUES
(1, 1, '张三数码旗舰店', '手机、电脑、数码配件', '400-123-4567', 1, 4.85);

-- 插入商品类别测试数据
INSERT INTO `category` (`category_id`, `parent_id`, `category_name`, `level`, `sort_order`, `category_status`, `path`) VALUES
(1, 0, '数码家电', 1, 1, 1, '/1/'),
(2, 1, '手机通讯', 2, 1, 1, '/1/2/'),
(3, 2, '智能手机', 3, 1, 1, '/1/2/3/');

-- 插入SPU测试数据
INSERT INTO `spu` (`spu_id`, `shop_id`, `category_id`, `brand_name`, `spu_name`, `selling_point`, `main_image`, `spu_status`, `sale_count`) VALUES
(1, 1, 3, 'Apple', 'iPhone 15 Pro', 'A17 Pro芯片，钛金属设计，4800万像素主摄', 'https://example.com/images/iphone15pro.jpg', 1, 1000);

-- 插入SKU测试数据
INSERT INTO `sku` (`sku_id`, `spu_id`, `sku_code`, `price`, `cost_price`, `stock`, `lock_stock`, `spec_attributes`, `is_default`) VALUES
(1, 1, 'IP15P-128-BLACK', 7999.00, 6500.00, 100, 5, '{"颜色":"黑色","存储":"128GB"}', 1),
(2, 1, 'IP15P-256-WHITE', 8999.00, 7200.00, 80, 3, '{"颜色":"白色","存储":"256GB"}', 0);

-- 插入购物车测试数据
INSERT INTO `cart` (`cart_id`, `user_id`) VALUES
(1, 2),
(2, 3);

-- 插入购物车项测试数据
INSERT INTO `cart_item` (`cart_item_id`, `cart_id`, `sku_id`, `quantity`, `price`, `checked`, `valid`) VALUES
(1, 1, 1, 2, 7999.00, TRUE, TRUE);

-- 插入订单测试数据
INSERT INTO `order` (`order_id`, `order_no`, `user_id`, `total_amount`, `pay_amount`, `freight_amount`, `discount_amount`, `order_status`, `payment_status`, `receiver_name`, `receiver_phone`, `receiver_address`) VALUES
(1, 'ORD202604200001', 2, 15998.00, 15998.00, 0.00, 0.00, 2, 1, '李四', '13800138002', '北京市朝阳区某某街道123号'),
(2, 'ORD202604200002', 3, 8999.00, 8999.00, 10.00, 0.00, 1, 0, '王五', '13800138003', '上海市浦东新区某某路456号');

-- 插入订单项测试数据
INSERT INTO `order_item` (`item_id`, `order_id`, `sku_id`, `product_name`, `price`, `quantity`, `spec_attr`, `image_url`) VALUES
(1, 1, 1, 'iPhone 15 Pro', 7999.00, 2, '颜色:黑色,存储:128GB', 'https://example.com/images/iphone15pro_black.jpg'),
(2, 2, 2, 'iPhone 15 Pro', 8999.00, 1, '颜色:白色,存储:256GB', 'https://example.com/images/iphone15pro_white.jpg');

-- 插入评论测试数据
INSERT INTO `review` (`review_id`, `user_id`, `sku_id`, `order_id`, `rating`, `comment`, `status`) VALUES
(1, 2, 1, 1, 5, '手机非常好用，拍照效果很棒！', 'approved');

-- 插入支付测试数据
INSERT INTO `payment` (`payment_id`, `order_id`, `amount`, `pay_type`, `status`, `third_party_trade_no`, `paid_at`) VALUES
('PAY202604200001', 'ORD202604200001', 1599800, 'alipay', 'PAID', '2025042022001156789012345678', '2026-04-20 10:30:00');

-- 插入物流测试数据
INSERT INTO `logistics` (`logistics_id`, `order_id`, `courier_company`, `tracking_number`, `shipment_time`, `estimated_arrival`, `status`) VALUES
(1, 1, '顺丰速运', 'SF1234567890', '2026-04-20 14:00:00', '2026-04-22 18:00:00', 2);

-- =============================================
-- DDL脚本执行完成
-- =============================================
