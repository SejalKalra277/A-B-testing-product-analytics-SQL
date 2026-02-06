-- =====================================================
-- Data Generation for A/B Testing & Product Analytics
-- =====================================================

USE ab_test_portfolio;

-- -----------------------
-- Helper numbers table
-- -----------------------
CREATE TABLE IF NOT EXISTS numbers (
  n INT PRIMARY KEY
);

/* Insert 50,000 numbers using cross joins (creates up to 100,000 then LIMIT) */
INSERT INTO numbers (n)
SELECT a.n + b.n * 10 + c.n * 100 + d.n * 1000 + e.n * 10000 + 1
FROM
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) e
LIMIT 50000;

-- -----------------------
-- Insert users
-- ----------------------
INSERT INTO users (user_id, experiment_group, signup_time, country, device)
SELECT
  n AS user_id,
  CASE WHEN n % 2 = 0 THEN 'control' ELSE 'treatment' END AS experiment_group,
  DATE_ADD('2025-06-01 09:00:00', INTERVAL FLOOR(RAND() * 90) DAY) AS signup_time,
  CASE
    WHEN RAND() < 0.45 THEN 'IN'
    WHEN RAND() < 0.80 THEN 'US'
    ELSE 'CA'
  END AS country,
  CASE
    WHEN RAND() < 0.50 THEN 'android'
    WHEN RAND() < 0.80 THEN 'ios'
    ELSE 'web'
  END AS device
FROM numbers;

-- -----------------------
-- Insert events (3 per user)
-- -----------------------
INSERT INTO events (user_id, event_type, event_time)
SELECT
  u.user_id,
  e.event_type,
  DATE_ADD(u.signup_time, INTERVAL e.minute_offset MINUTE) AS event_time
FROM users u
JOIN (
  SELECT 'exposed' AS event_type, 5 AS minute_offset
  UNION ALL SELECT 'viewed_pricing', 25
  UNION ALL SELECT 'feature_used', 60
) e;

-- -----------------------
-- Insert purchases with embedded uplift
-- Control ≈ 7% conversion
-- Treatment ≈ 11% conversion
-- -----------------------
INSERT INTO purchases (user_id, amount, purchase_time)
SELECT
  u.user_id,
  ROUND(10 + RAND() * 90, 2) AS amount,
  DATE_ADD(u.signup_time, INTERVAL (120 + FLOOR(RAND() * 10080)) MINUTE) AS purchase_time
FROM users u
WHERE
  (u.experiment_group = 'control' AND RAND() < 0.07)
  OR
  (u.experiment_group = 'treatment' AND RAND() < 0.11);
  
  
-- -----------------------
-- Sanity checks
-- -----------------------

/* Row counts */
SELECT 'users' AS table_name, COUNT(*) AS rows_cnt FROM users
UNION ALL
SELECT 'events', COUNT(*) FROM events
UNION ALL
SELECT 'purchases', COUNT(*) FROM purchases
UNION ALL
SELECT 'numbers', COUNT(*) FROM numbers;

