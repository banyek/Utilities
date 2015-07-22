-- CREATES DATABASE TABLE for monitor_space utility

CREATE TABLE `dbinfo`.`table_sizes` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hostname` varchar(64) NOT NULL,
  `table_schema` varchar(64) NOT NULL,
  `table_name` varchar(64) NOT NULL,
  `table_rows` bigint(21),
  `data_size` decimal(10,2) NOT NULL,
  `index_size` decimal(10,2) NOT NULL,
  `total_size` decimal(10,2) NOT NULL,
  `create_time` datetime,
  `update_time` datetime,
  `check_time` datetime,
PRIMARY KEY (`id`));
