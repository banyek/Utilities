-- CREATES DATABASE TABLE for monitor_space utility

CREATE TABLE `test`.`table_sizes` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `tablename` varchar(50) DEFAULT NULL,
  `datasize` decimal(10,2) DEFAULT NULL,
  `indexsize` decimal(10,2) DEFAULT NULL,
  `totalsize` decimal(10,2) DEFAULT NULL,
PRIMARY KEY (`id`);
