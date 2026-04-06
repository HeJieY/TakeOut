#!/bin/bash

# 数据库初始化脚本 - Linux版本
# 用于初始化takeout数据库的表结构和初始数据

# 数据库配置
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="takeout"
DB_USER="root"

# Please enter your MySQL password
read -sp "Enter your MySQL password: " DB_PASS

echo "开始初始化数据库..."

# 创建数据库（如果不存在）
mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASS -e "CREATE DATABASE IF NOT EXISTS $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "数据库创建完成，开始创建表结构和插入数据..."

# 执行SQL语句
mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASS $DB_NAME << 'EOF'

-- 创建表结构
CREATE TABLE IF NOT EXISTS admin (
    aId INT AUTO_INCREMENT PRIMARY KEY,
    aName VARCHAR(30) NOT NULL,
    aPassword VARCHAR(100) NOT NULL,
    UNIQUE KEY table_name_aName_uindex (aName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS consumer (
    cId INT AUTO_INCREMENT PRIMARY KEY,
    cName VARCHAR(25) NOT NULL,
    cSex CHAR(2) NULL,
    cAge SMALLINT(6) NULL,
    cTel CHAR(11) NOT NULL,
    cEmail VARCHAR(40) NULL,
    cAddress VARCHAR(100) NULL,
    cPassword VARCHAR(100) NOT NULL,
    cBalance DECIMAL(10,2) NULL,
    UNIQUE KEY cName (cName),
    UNIQUE KEY consumer_cTel_uindex (cTel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS shop (
    sId INT AUTO_INCREMENT PRIMARY KEY,
    sName VARCHAR(40) NOT NULL,
    sPassword VARCHAR(100) NOT NULL,
    sTel CHAR(11) NOT NULL,
    sAddress VARCHAR(100) NOT NULL,
    managerName VARCHAR(20) NULL,
    managerEmail VARCHAR(40) NULL,
    sPictureUrl VARCHAR(100) NULL,
    score DECIMAL(2,1) NULL,
    UNIQUE KEY sName (sName),
    UNIQUE KEY shop_sTel_uindex (sTel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS commentary (
    CoID INT AUTO_INCREMENT PRIMARY KEY,
    CoTime DATETIME NOT NULL,
    content VARCHAR(1024) NOT NULL,
    stars INT NULL,
    Cid INT NOT NULL,
    SID INT NOT NULL,
    FOREIGN KEY (Cid) REFERENCES consumer (cId),
    FOREIGN KEY (SID) REFERENCES shop (sId),
    KEY Cid (Cid),
    KEY SID (SID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS consumerreply (
    CID INT NOT NULL,
    CoID INT NOT NULL,
    CoTime DATETIME NOT NULL,
    content VARCHAR(1024) NOT NULL,
    PRIMARY KEY (CID, CoID, CoTime),
    FOREIGN KEY (CID) REFERENCES consumer (cId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (CoID) REFERENCES commentary (CoID) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS contact (
    CID INT NOT NULL,
    SID INT NOT NULL,
    CTime DATETIME NOT NULL,
    content VARCHAR(1024) NOT NULL,
    CState VARCHAR(10) NOT NULL,
    PRIMARY KEY (CID, SID, CTime),
    FOREIGN KEY (CID) REFERENCES consumer (cId),
    FOREIGN KEY (SID) REFERENCES shop (sId),
    KEY SID (SID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS goods (
    gId INT AUTO_INCREMENT PRIMARY KEY,
    gName VARCHAR(40) NOT NULL,
    gPrice DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL,
    type VARCHAR(20) NOT NULL,
    buyCount INT DEFAULT 0 NOT NULL,
    gPictureUrl VARCHAR(1000) NULL,
    gPraise DECIMAL(2,2) NULL,
    sId INT NOT NULL,
    `desc` VARCHAR(1024) NOT NULL,
    FOREIGN KEY (sId) REFERENCES shop (sId),
    KEY sId (sId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS orderhistory (
    oId INT AUTO_INCREMENT PRIMARY KEY,
    oState VARCHAR(10) NOT NULL,
    oTime DATETIME NOT NULL,
    oNum INT NOT NULL,
    cost DECIMAL(10,2) NOT NULL,
    CID INT NOT NULL,
    GID INT NOT NULL,
    FOREIGN KEY (GID) REFERENCES goods (gId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (CID) REFERENCES consumer (cId) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS shoppingcart (
    CID INT NOT NULL,
    GID INT NOT NULL,
    num INT NOT NULL,
    total DECIMAL(10,2) NULL,
    PRIMARY KEY (CID, GID),
    FOREIGN KEY (CID) REFERENCES consumer (cId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (GID) REFERENCES goods (gId) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS shopreply (
    SID INT NOT NULL,
    CoID INT NOT NULL,
    CoTime DATETIME NOT NULL,
    content VARCHAR(1024) NOT NULL,
    PRIMARY KEY (SID, CoID, CoTime),
    FOREIGN KEY (SID) REFERENCES shop (sId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (CoID) REFERENCES commentary (CoID) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS sys_log (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    USERNAME VARCHAR(50) NULL,
    OPERATION VARCHAR(50) NULL,
    _TIME INT NULL,
    METHOD VARCHAR(200) NULL,
    PARAMS VARCHAR(500) NULL,
    IP VARCHAR(64) NULL,
    CREATE_TIME DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 创建视图
CREATE OR REPLACE VIEW commentary_view AS
SELECT c.CoID AS id, c.Cid AS cid, s.sId AS sid, con.cName AS cname,
       s.sName AS sname, c.CoTime AS ctime, c.content AS content, c.stars AS stars
FROM commentary c
JOIN consumer con ON c.Cid = con.cId
JOIN shop s ON c.SID = s.sId;

CREATE OR REPLACE VIEW consumerreply_view AS
SELECT c.cId AS cid, cr.CoID AS coid, c.cName AS cname,
       cr.CoTime AS cotime, cr.content AS content
FROM consumerreply cr
JOIN consumer c ON cr.CID = c.cId;

CREATE OR REPLACE VIEW contact_view AS
SELECT c.cId AS cid, s.sId AS sid, c.cName AS cname,
       s.sName AS sname, ct.CTime AS ctime, ct.CState AS state, ct.content AS content
FROM contact ct
JOIN consumer c ON ct.CID = c.cId
JOIN shop s ON ct.SID = s.sId;

CREATE OR REPLACE VIEW orderhistory_view AS
SELECT o.oId AS id, g.sId AS sid, o.CID AS cid, o.GID AS gid,
       s.sName AS shopName, g.gName AS goodsName, o.oTime AS buyTime,
       g.gPictureUrl AS picture, o.oNum AS num, g.gPrice AS price,
       o.cost AS total, o.oState AS state, c.cName AS consumerName
FROM orderhistory o
JOIN goods g ON g.gId = o.GID
JOIN shop s ON s.sId = g.sId
JOIN consumer c ON c.cId = o.CID;

CREATE OR REPLACE VIEW shoppingcart_view AS
SELECT sc.CID AS cid, g.sId AS sid, sc.GID AS gid,
       s.sName AS shopName, g.gName AS goodsName, g.gPictureUrl AS picture,
       sc.num AS num, g.gPrice AS price, sc.total AS total
FROM shop s
JOIN goods g ON s.sId = g.sId
JOIN shoppingcart sc ON g.sId = sc.GID;

CREATE OR REPLACE VIEW shopreply_view AS
SELECT s.sId AS sid, sr.CoID AS coid, s.sName AS sname,
       sr.CoTime AS cotime, sr.content AS content
FROM shopreply sr
JOIN shop s ON sr.SID = s.sId;

-- 插入初始数据（密码使用明文存储）
-- Admin表数据
INSERT INTO admin (aId, aName, aPassword) VALUES (1, 'mai', '1234');

-- Consumer表数据
INSERT INTO consumer (cId, cName, cSex, cAge, cTel, cEmail, cAddress, cPassword, cBalance) VALUES 
(1, 'Zhang San', '男', 1, '13959257650', '1@2', 'haiyun', '1234', 2.34),
(2, '李四', '男', 18, '13306325913', NULL, '厦门市思明区', '654321', NULL),
(3, '王少', NULL, NULL, '18765467678', '465321687@qq.com', NULL, '987456', NULL),
(4, 'ajfakjf', '男', NULL, '18308909098', NULL, NULL, '123456', NULL),
(5, '王五', '男', 18, '18976543567', '', NULL, '123', 100.00),
(10, 'hyttyh', NULL, 13, '14567432786', NULL, NULL, '18888', 0.00),
(17, 'lizn', NULL, NULL, '12345678908', NULL, NULL, 'haode', 0.00),
(20, 'atom', '男', 1, '15396277909', '123@mail', '465664', '1234', 0.00);

-- Shop表数据
INSERT INTO shop (sId, sName, sPassword, sTel, sAddress, managerName, managerEmail, sPictureUrl, score) VALUES 
(1, 'mai', '1234', '18308958589', '海韵一条街', '花展枝', 'mlfaf', NULL, 4.5),
(2, '益合堂', '789954', '11111111111', '海韵一条街', 'hzoaixn', NULL, NULL, NULL),
(3, '黄焖鸡', '444451', '10989786543', '海韵一条街', 'llll', NULL, NULL, 4.2),
(4, '东北饺子馆', '3131093', '13959687541', '海韵下坡路', 'wangzi', '22@33', NULL, 1.0),
(8, 'kaige', '18976', '17865453789', 'beijings', 'kaige', NULL, NULL, NULL),
(9, 'bgjakgjjhk', '3131093', '12345654348', 'fahuajfj', NULL, NULL, NULL, NULL);

-- Commentary表数据
INSERT INTO commentary (CoID, CoTime, content, stars, Cid, SID) VALUES 
(2, '2019-07-04 23:47:01', 'Just so so', 3, 2, 1),
(3, '2019-06-24 12:33:17', 'Bad!', 1, 2, 1),
(4, '2019-07-04 00:00:00', 'dada', 5, 2, 2),
(5, '2019-07-04 23:46:17', 'dada', 5, 2, 2),
(6, '2019-07-04 23:47:01', 'dada', 5, 2, 2),
(7, '2019-07-12 16:18:00', 'woc', 5, 1, 1),
(8, '2019-07-16 09:57:51', 'kfannajgnanjnnnn', 5, 1, 1),
(9, '2019-07-16 10:01:55', 'jsglsjgls', 5, 1, 1),
(10, '2019-07-16 11:14:05', 'haoyayayayayaa', 5, 1, 1),
(11, '2019-07-16 11:14:39', 'niganma', 5, 1, 1),
(12, '2019-07-16 11:15:51', 'gjhvgjvj', 5, 1, 1),
(13, '2019-07-16 11:30:54', 'nihaoya', 5, 1, 1);

-- ConsumerReply表数据
INSERT INTO consumerreply (CID, CoID, CoTime, content) VALUES 
(1, 2, '2019-07-06 22:36:43', '爱你三千遍！'),
(1, 2, '2019-07-07 16:48:57', 'hgfgfjhg'),
(1, 3, '2019-07-06 22:38:46', '上面的Thank you做什么？'),
(2, 3, '2019-06-24 12:33:17', 'Just so so'),
(20, 3, '2019-07-10 11:23:17', '可恶');

-- Contact表数据
INSERT INTO contact (CID, SID, CTime, content, CState) VALUES 
(1, 1, '2019-06-24 12:33:17', 'Hello world', '1'),
(1, 1, '2019-07-04 21:07:40', 'Hello world', '1'),
(1, 1, '2019-07-04 23:46:17', 'Hello world', '1'),
(1, 1, '2019-07-04 23:47:01', 'Hello world', '1'),
(1, 1, '2019-07-11 11:34:09', 'ky', '1'),
(1, 1, '2019-07-11 11:36:40', 'nihao', '1'),
(1, 1, '2019-07-11 11:41:24', 'HYT nb', '1'),
(1, 1, '2019-07-11 11:43:10', 'hakjfaf', '1'),
(1, 1, '2019-07-11 16:40:57', '你好', '0'),
(1, 1, '2019-07-11 16:41:52', '可以哟', '0'),
(1, 1, '2019-07-11 16:45:24', '你好', '0'),
(1, 1, '2019-07-11 16:51:03', 'nb', '0'),
(1, 1, '2019-07-11 16:51:36', '？？？', '1'),
(1, 1, '2019-07-11 16:53:10', '嗯嗯', '0'),
(1, 1, '2019-07-11 16:54:56', '好吃', '0'),
(1, 1, '2019-07-11 16:55:05', 'md', '1'),
(1, 1, '2019-07-11 16:58:02', 'fafa', '0'),
(1, 1, '2019-07-11 16:58:30', 'faf', '1'),
(1, 1, '2019-07-11 17:00:23', 'faf', '0'),
(1, 1, '2019-07-11 17:00:50', 'dafd', '0'),
(1, 1, '2019-07-11 17:04:27', 'faf', '0'),
(1, 1, '2019-07-11 17:05:34', 'haode', '0'),
(1, 1, '2019-07-11 17:05:45', 'enen', '1'),
(1, 1, '2019-07-11 17:06:24', '好吃', '1'),
(1, 1, '2019-07-11 17:06:34', '谢谢', '0'),
(1, 1, '2019-07-11 17:17:01', 'ddd', '0'),
(1, 1, '2019-07-11 17:18:30', 'fafa', '0'),
(1, 1, '2019-07-11 17:19:11', 'gaga gagfagfag', '0'),
(1, 1, '2019-07-11 17:20:18', 'fafa', '1'),
(1, 1, '2019-07-11 17:21:37', 'gagagagagaaggagagag', '0'),
(1, 1, '2019-07-11 17:23:02', 'fafaf', '0'),
(1, 1, '2019-07-11 17:23:57', 'HYT nb', '0'),
(1, 1, '2019-07-11 17:27:24', 'nb', '0'),
(1, 1, '2019-07-11 19:33:22', 'li', '0'),
(1, 1, '2019-07-12 11:09:09', 'fuygug', '1'),
(1, 1, '2019-07-14 16:54:47', 'nihaoya', '0'),
(1, 1, '2019-07-14 16:55:03', '好呀', '1'),
(1, 1, '2019-07-15 17:28:21', 'nihao', '1'),
(1, 1, '2019-07-15 17:28:31', 'jjj', '1'),
(1, 1, '2019-07-15 22:51:45', '你好呀', '1'),
(1, 1, '2019-07-15 23:45:07', '好吃的不行', '1'),
(1, 1, '2019-07-16 10:09:40', 'ok', '1'),
(1, 3, '2019-06-24 12:33:17', 'Hello world', '0'),
(1, 3, '2019-07-11 17:08:42', 'fff', '0'),
(1, 3, '2019-07-11 17:09:55', 'fff', '0'),
(1, 3, '2019-07-11 17:15:07', 'ff', '0'),
(1, 3, '2019-07-11 17:17:22', 'ddd', '0'),
(1, 3, '2019-07-11 17:18:47', 'ffff', '0'),
(1, 3, '2019-07-11 17:21:57', 'gfafaf', '0'),
(3, 2, '2019-06-24 12:33:17', 'Hello', '0'),
(20, 1, '2019-07-11 11:37:24', 'kyd', '1'),
(20, 1, '2019-07-11 11:38:44', 'nbo', '1'),
(20, 1, '2019-07-11 11:41:58', '我也nb', '0'),
(20, 1, '2019-07-11 17:06:44', 'atom', '1'),
(20, 1, '2019-07-11 17:07:23', 'atom!', '1'),
(20, 1, '2019-07-11 17:14:05', 'dada', '1'),
(20, 1, '2019-07-11 17:19:41', 'fafaf', '1'),
(20, 1, '2019-07-11 17:21:50', 'atom!', '1');

-- Goods表数据
INSERT INTO goods (gId, gName, gPrice, stock, type, buyCount, gPictureUrl, gPraise, sId, `desc`) VALUES 
(3, '炒面', 200.00, 1, '主食', 331, 'http://localhost:8080/takeout/upload/201907160921343.jpg', 0.00, 1, '好康的，也是好吃的'),
(5, '薄荷', 200.00, 9982, '小吃', 19, 'http://localhost:8080/takeout/upload/201907022119344.jpg', 0.85, 1, '很贵哟，慎重购买'),
(6, '千叶豆腐', 22.00, 13, '主食', 9, 'http://localhost:8080/takeout/upload/201907141207575.jpg', 0.00, 1, 'HYT经常吃'),
(17, '水果捞', 20.00, 11, '小吃', 2, 'http://localhost:8080/takeout/upload/201907022119591.jpg', 0.00, 1, '一会他们就要去买了'),
(22, '烤鲈鱼', 120.00, 25, '主食', 659, 'http://localhost:8080/takeout/upload/201907022120098.jpg', 0.00, 1, '谁脱单谁请客！'),
(23, '口水鸡', 30.00, 19, '小吃', 6, 'http://localhost:8080/takeout/upload/201907022120527.jpg', 0.00, 1, '真的好吃'),
(24, '辣子鸡', 20.00, 18, '小吃', 76, 'http://localhost:8080/takeout/upload/201907022121279.jpg', 0.00, 1, '触动你火辣的心！'),
(25, '炒饭', 19.00, 84, '主食', 10, 'http://localhost:8080/takeout/upload/201907022122326.jpg', 0.00, 1, '有坤的最爱！'),
(26, '干锅包菜', 15.00, 14, '主食', 537, 'http://localhost:8080/takeout/upload/2019070221230510.jpg', 0.00, 1, '锅会干，但你的心不会！'),
(27, '可口可乐', 5.00, 900, '饮料', 53, 'http://localhost:8080/takeout/upload/2019070221263112.jpg', 0.00, 1, '一个肥宅简简单单的快落'),
(28, '农夫山泉', 3.00, 900, '饮料', 64, 'http://localhost:8080/takeout/upload/2019070221272613.jpg', 0.00, 1, '农夫三拳，有点疼！'),
(29, '海南牌椰汁', 5.00, 199, '小吃', 75, 'http://localhost:8080/takeout/upload/2019070221280314.jpg', 0.00, 1, '我从小喝到大！'),
(30, '薄荷汁', 6.00, 100, '饮料', 8, 'http://localhost:8080/takeout/upload/2019070221284411.jpg', 0.00, 1, '凉透你的心扉！'),
(31, 'fan', 10.00, 9, '主食', 76, 'http://localhost:8080/takeout/upload/201907031009226.jpg', 0.00, 1, '好吃'),
(32, '加滑稽', 12.00, 13, '小吃', 34, 'http://localhost:8080/takeout/upload/201907141439312.jpg', 0.00, 1, '好吃的'),
(33, '千叶豆腐', 22.00, 20, '主食', 86, 'http://localhost:8080/takeout/upload/201907141208245.jpg', 0.00, 1, 'HYT经常吃');

-- ShoppingCart表数据
INSERT INTO shoppingcart (CID, GID, num, total) VALUES 
(1, 3, 1, 200.00),
(1, 5, 3, 600.00),
(20, 3, 1, 200.00),
(20, 22, 18, 2160.00);

-- ShopReply表数据
INSERT INTO shopreply (SID, CoID, CoTime, content) VALUES 
(1, 2, '2019-07-07 16:41:56', 'haoya'),
(1, 2, '2019-07-12 08:40:59', '无敌是多么寂寞'),
(1, 3, '2019-07-04 21:10:20', 'Thank you'),
(1, 3, '2019-07-07 11:27:27', '你好'),
(1, 7, '2019-07-14 13:07:11', '干什么腻？'),
(1, 7, '2019-07-15 17:27:53', 'gjg');

-- OrderHistory表数据
INSERT INTO orderhistory (oId, oState, oTime, oNum, cost, CID, GID) VALUES 
(4, '已完成', '2019-06-28 02:03:21', 12, 100.00, 1, 3),
(5, '待评价', '2019-07-02 00:00:00', 1, 200.00, 1, 5),
(6, '已完成', '2019-07-02 00:00:00', 1, 200.00, 1, 3),
(7, '已取消', '2019-07-02 00:00:00', 2, 200.00, 1, 3),
(8, '已取消', '2019-07-02 00:00:00', 2, 3.00, 1, 28),
(9, '已取消', '2019-07-02 00:00:00', 8, 200.00, 1, 3),
(10, '未完成', '2019-07-02 00:00:00', 10, 200.00, 1, 3),
(11, '未完成', '2019-07-02 00:00:00', 2, 200.00, 1, 3),
(12, '未完成', '2019-07-02 00:00:00', 2, 200.00, 1, 3),
(13, '未完成', '2019-07-03 00:00:00', 1, 6.00, 1, 30),
(14, '待评价', '2019-07-04 20:50:34', 1, 200.00, 1, 3),
(15, '待评价', '2019-07-05 11:01:57', 1, 22.00, 1, 6),
(16, '未完成', '2019-07-05 17:04:16', 1, 22.00, 1, 33),
(17, '未完成', '2019-07-07 11:39:12', 1, 200.00, 1, 3),
(18, '未完成', '2019-07-07 16:45:16', 3, 120.00, 1, 22),
(19, '未完成', '2019-07-09 19:38:15', 1, 30.00, 1, 23),
(20, '未完成', '2019-07-09 19:41:28', 1, 200.00, 1, 3),
(21, '待评价', '2019-07-10 11:15:18', 3, 19.00, 20, 25),
(22, '已取消', '2019-07-12 09:53:34', 1, 200.00, 1, 3),
(23, '已取消', '2019-07-12 14:48:41', 1, 200.00, 1, 3),
(24, '未完成', '2019-07-12 18:50:18', 1, 200.00, 1, 5),
(25, '未完成', '2019-07-12 18:51:39', 1, 200.00, 1, 5),
(26, '未完成', '2019-07-12 19:15:41', 1, 200.00, 1, 5),
(27, '未完成', '2019-07-12 19:15:41', 1, 120.00, 1, 22),
(28, '未完成', '2019-07-12 19:18:24', 1, 200.00, 1, 3),
(29, '未完成', '2019-07-12 19:18:24', 1, 200.00, 1, 5),
(30, '未完成', '2019-07-12 19:18:24', 1, 120.00, 1, 22),
(31, '待评价', '2019-07-13 16:55:47', 2, 22.00, 1, 6),
(32, '未完成', '2019-07-13 16:55:47', 2, 20.00, 1, 24),
(33, '待评价', '2019-07-13 18:22:12', 2, 22.00, 1, 6),
(34, '未完成', '2019-07-14 13:22:16', 1, 200.00, 1, 5),
(35, '待评价', '2019-07-14 13:22:16', 1, 22.00, 1, 6),
(36, '待评价', '2019-07-14 13:22:16', 1, 120.00, 1, 22),
(37, '待评价', '2019-07-14 13:22:16', 1, 20.00, 1, 24),
(38, '待评价', '2019-07-14 13:22:16', 1, 5.00, 1, 29),
(39, '待评价', '2019-07-14 13:22:16', 1, 10.00, 1, 31),
(40, '待评价', '2019-07-14 20:45:57', 3, 200.00, 1, 5),
(41, '未完成', '2019-07-14 20:51:00', 1, 200.00, 1, 3),
(42, '待评价', '2019-07-14 20:51:17', 1, 200.00, 1, 5),
(43, '未完成', '2019-07-14 20:51:52', 1, 200.00, 1, 5),
(44, '未完成', '2019-07-14 20:52:03', 1, 200.00, 1, 5),
(45, '待评价', '2019-07-14 20:52:53', 1, 200.00, 1, 5),
(46, '待评价', '2019-07-14 20:53:40', 1, 200.00, 1, 5),
(47, '待评价', '2019-07-14 20:55:28', 1, 200.00, 1, 5),
(48, '待评价', '2019-07-14 20:55:49', 1, 200.00, 1, 5),
(49, '待评价', '2019-07-14 20:57:14', 1, 200.00, 1, 5),
(50, '已完成', '2019-07-14 20:57:26', 1, 200.00, 1, 5),
(51, '待评价', '2019-07-14 21:02:35', 1, 200.00, 1, 5),
(52, '待评价', '2019-07-14 21:02:54', 1, 22.00, 1, 6),
(53, '已完成', '2019-07-15 08:30:09', 1, 200.00, 1, 5),
(54, '已完成', '2019-07-15 08:45:21', 3, 200.00, 1, 5),
(55, '已完成', '2019-07-15 08:45:21', 1, 120.00, 1, 22),
(56, '已完成', '2019-07-15 17:29:00', 1, 200.00, 1, 5),
(57, '已完成', '2019-07-15 17:29:00', 1, 120.00, 1, 22),
(58, '已完成', '2019-07-15 17:29:00', 2, 19.00, 1, 25),
(59, '待评价', '2019-07-15 23:43:15', 1, 200.00, 1, 5),
(60, '待评价', '2019-07-15 23:43:15', 1, 22.00, 1, 6),
(61, '待评价', '2019-07-15 23:43:15', 2, 120.00, 1, 22),
(62, '待评价', '2019-07-15 23:43:15', 1, 30.00, 1, 23),
(63, '已完成', '2019-07-15 23:43:15', 1, 19.00, 1, 25),
(64, '待评价', '2019-07-15 23:43:15', 1, 15.00, 1, 26);

EOF

echo "数据库初始化完成！"
echo "数据库: $DB_NAME"
echo "用户: $DB_USER"
