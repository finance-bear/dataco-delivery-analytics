SELECT COUNT(*) FROM cleaning;
DESCRIBE cleaning;

#DATATYPE, NULL, BLANK AND DUPLICATE (USING DYNAMIC SQL)
SET SESSION group_concat_max_len = 1000000;
SELECT
    GROUP_CONCAT(
        CONCAT(
            'SELECT ',
            QUOTE(COLUMN_NAME), ' AS column_name, ',
           
            QUOTE(DATA_TYPE), ' AS data_type, ',

            'COUNT(*) AS total_rows, ',

            'COUNT(', COLUMN_NAME, ') AS non_null_cnt, ',

            'COUNT(*) - COUNT(', COLUMN_NAME, ') AS null_cnt, ',

            'ROUND(100.0 * (COUNT(*) - COUNT(',
                COLUMN_NAME,
            ')) / NULLIF(COUNT(*), 0), 2) AS null_pct, ',

            CASE
                WHEN DATA_TYPE IN (
                    'char', 'varchar', 'tinytext',
                    'text', 'mediumtext', 'longtext'
                )
                THEN CONCAT(
                    'SUM(CASE WHEN TRIM(', COLUMN_NAME,
                    ") = '' THEN 1 ELSE 0 END)"
                )
                ELSE 'NULL'
            END,
            ' AS blank_cnt, ',

            'COUNT(DISTINCT ', COLUMN_NAME, ') AS distinct_cnt ',

            'FROM cleaning'
        )
        ORDER BY ORDINAL_POSITION
        SEPARATOR ' UNION ALL '
    ) INTO @profiling_sql

FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dataco' AND TABLE_NAME = 'cleaning';

SELECT @profiling_sql;
PREPARE stmt FROM @profiling_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;







 
 
    

