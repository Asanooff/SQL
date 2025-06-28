CREATE DATABASE final_project;

UPDATE customers SET Gender = NULL WHERE Gender ='';
UPDATE customers SET Age = NULL WHERE Age ='';
ALTER TABLE customers MODIFY Age INT NULL;

SELECT * FROM customers;

CREATE TABLE transactions
(date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL(10,3),
Sum_payment DECIMAL (10,2));

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\transactions_info.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'secure_file_priv';

SELECT * FROM customers;
SELECT * FROM transactions;


# 1. Посчитать количество месяцев с операциями по каждому клиенту
SELECT
    ID_client
FROM (
    SELECT
        ID_client,
        COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS active_months
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
    GROUP BY ID_client
) AS client_months
WHERE active_months = 12;

# Метрики по клиентам с непрерывной историей
SELECT
    t.ID_client,
    ROUND(AVG(t.Sum_payment), 2) AS avg_check,
    ROUND(SUM(t.Sum_payment) / 12, 2) AS avg_amount_per_month,
    COUNT(t.Id_check) AS total_operations
FROM transactions t
JOIN (
    SELECT
        ID_client
    FROM (
        SELECT
            ID_client,
            COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS active_months
        FROM transactions
        WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
        GROUP BY ID_client
    ) AS client_months
    WHERE active_months = 12
) AS active_clients ON t.ID_client = active_clients.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY t.ID_client
ORDER BY t.ID_client;

# 2. a) Средняя сумма чека в каждом месяце
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    ROUND(AVG(Sum_payment), 2) AS avg_check
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

# b) Среднее количество операций в месяц
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(Id_check) AS total_operations
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

# c) Кол-во клиентов, совершивших операции в месяц
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(DISTINCT ID_client) AS active_clients
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

# d) Доля операций и суммы в месяц от общего за год
-- Общая сумма и количество операций за год
SELECT
    COUNT(Id_check) AS total_operations_year,
    SUM(Sum_payment) AS total_sum_year
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31';

-- Доля по месяцам (в процентах от года)
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    ROUND(COUNT(Id_check) / 381302 * 100, 2) AS operations_share_percent,
    ROUND(SUM(Sum_payment) / 3613837.21 * 100, 2) AS amount_share_percent
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

# 3. Возрастные группы с шагом 10 лет и группы с неизвестным возрастом
# Назначим возрастные группы
SELECT
    CASE
        WHEN c.Age IS NULL THEN 'Unknown'
        WHEN c.Age < 10 THEN '00–09'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10–19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20–29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30–39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40–49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50–59'
        WHEN c.Age BETWEEN 60 AND 69 THEN '60–69'
        ELSE '70+'
    END AS age_group,
    COUNT(t.Id_check) AS total_operations,
    ROUND(SUM(t.Sum_payment), 2) AS total_amount
FROM transactions t
JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY age_group
ORDER BY age_group;

# Те же группы — поквартально + средние значения
SELECT
    CASE
        WHEN c.Age IS NULL THEN 'Unknown'
        WHEN c.Age < 10 THEN '00–09'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10–19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20–29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30–39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40–49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50–59'
        WHEN c.Age BETWEEN 60 AND 69 THEN '60–69'
        ELSE '70+'
    END AS age_group,
    CONCAT('Q', QUARTER(t.date_new)) AS quarter,
    COUNT(t.Id_check) AS total_operations,
    ROUND(SUM(t.Sum_payment), 2) AS total_amount,
    ROUND(AVG(t.Sum_payment), 2) AS avg_check
FROM transactions t
JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY age_group, quarter
ORDER BY age_group, quarter;

# Расчёт доли каждой возрастной группы от общего
SELECT
    CASE
        WHEN c.Age IS NULL THEN 'Unknown'
        WHEN c.Age < 10 THEN '00–09'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10–19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20–29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30–39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40–49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50–59'
        WHEN c.Age BETWEEN 60 AND 69 THEN '60–69'
        ELSE '70+'
    END AS age_group,
    COUNT(t.Id_check) AS total_operations,
    ROUND(COUNT(t.Id_check) / 381302 * 100, 2) AS operations_percent,
    ROUND(SUM(t.Sum_payment), 2) AS total_amount,
    ROUND(SUM(t.Sum_payment) / 3613837.21 * 100, 2) AS amount_percent
FROM transactions t
JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY age_group
ORDER BY age_group;