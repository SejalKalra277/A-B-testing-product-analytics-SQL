-- =====================================================
-- A/B Testing & Product Analytics (MySQL)
-- =====================================================

USE ab_test_portfolio;

-- -----------------------------------------------------
-- Query 0: Row count sanity check
-- -----------------------------------------------------
SELECT 'users' AS table_name, COUNT(*) AS rows_cnt FROM users
UNION ALL
SELECT 'events', COUNT(*) FROM events
UNION ALL
SELECT 'purchases', COUNT(*) FROM purchases;


-- -----------------------------------------------------
-- Query 1: Sample balance (users per variant)
-- Business question: Are control and treatment balanced?
-- -----------------------------------------------------
SELECT
  experiment_group,
  COUNT(*) AS users
FROM users
GROUP BY experiment_group;


-- -----------------------------------------------------
-- Query 2: Event distribution (events by type)
-- Business question: Are expected event types present?
-- -----------------------------------------------------
SELECT
  event_type,
  COUNT(*) AS events
FROM events
GROUP BY event_type
ORDER BY events DESC;


-- -----------------------------------------------------
-- Query 3: Exposure + Feature usage validation by variant
-- Business question: Did tracking work and is exposure consistent?
-- -----------------------------------------------------
SELECT
  u.experiment_group,
  COUNT(DISTINCT u.user_id) AS users,

  COUNT(DISTINCT CASE WHEN e_exposed.user_id IS NOT NULL THEN u.user_id END) AS exposed_users,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN e_exposed.user_id IS NOT NULL THEN u.user_id END)
    / COUNT(DISTINCT u.user_id),
    2
  ) AS exposed_rate_pct,

  COUNT(DISTINCT CASE WHEN e_used.user_id IS NOT NULL THEN u.user_id END) AS feature_used_users,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN e_used.user_id IS NOT NULL THEN u.user_id END)
    / COUNT(DISTINCT u.user_id),
    2
  ) AS feature_used_rate_pct

FROM users u
LEFT JOIN events e_exposed
  ON e_exposed.user_id = u.user_id
 AND e_exposed.event_type = 'exposed'
LEFT JOIN events e_used
  ON e_used.user_id = u.user_id
 AND e_used.event_type = 'feature_used'
GROUP BY u.experiment_group;


-- -----------------------------------------------------
-- Query 4: Experiment summary by variant (conversion + revenue)
-- Business question: How do variants compare on conversion and ARPU?
-- Definition: Converted = at least one purchase.
-- -----------------------------------------------------
SELECT
  u.experiment_group,
  COUNT(DISTINCT u.user_id) AS users,
  COUNT(DISTINCT p.user_id) AS converters,
  ROUND(100.0 * COUNT(DISTINCT p.user_id) / COUNT(DISTINCT u.user_id), 2) AS conversion_rate_pct,
  ROUND(SUM(COALESCE(p.amount, 0)), 2) AS total_revenue,
  ROUND(SUM(COALESCE(p.amount, 0)) / COUNT(DISTINCT u.user_id), 2) AS arpu
FROM users u
LEFT JOIN purchases p
  ON p.user_id = u.user_id
GROUP BY u.experiment_group;


-- -----------------------------------------------------
-- Query 5: Uplift vs control (conversion pp + ARPU)
-- Business question: By how much did treatment outperform control?
-- -----------------------------------------------------
SELECT
  ROUND(
    100.0 * (
      (t.converters / t.users) -
      (c.converters / c.users)
    ),
    2
  ) AS conversion_uplift_pp,

  ROUND(
    (t.total_revenue / t.users) -
    (c.total_revenue / c.users),
    2
  ) AS arpu_uplift
FROM
  (
    SELECT
      COUNT(DISTINCT u.user_id) AS users,
      COUNT(DISTINCT p.user_id) AS converters,
      SUM(COALESCE(p.amount, 0)) AS total_revenue
    FROM users u
    LEFT JOIN purchases p ON p.user_id = u.user_id
    WHERE u.experiment_group = 'treatment'
  ) t
CROSS JOIN
  (
    SELECT
      COUNT(DISTINCT u.user_id) AS users,
      COUNT(DISTINCT p.user_id) AS converters,
      SUM(COALESCE(p.amount, 0)) AS total_revenue
    FROM users u
    LEFT JOIN purchases p ON p.user_id = u.user_id
    WHERE u.experiment_group = 'control'
  ) c;


-- -----------------------------------------------------
-- Query 6: Segment summary (by device + variant)
-- Business question: Does the effect vary across devices?
-- -----------------------------------------------------
SELECT
  u.device,
  u.experiment_group,
  COUNT(DISTINCT u.user_id) AS users,
  COUNT(DISTINCT p.user_id) AS converters,
  ROUND(100.0 * COUNT(DISTINCT p.user_id) / COUNT(DISTINCT u.user_id), 2) AS conversion_rate_pct,
  ROUND(SUM(COALESCE(p.amount, 0)) / COUNT(DISTINCT u.user_id), 2) AS arpu
FROM users u
LEFT JOIN purchases p
  ON p.user_id = u.user_id
GROUP BY u.device, u.experiment_group
ORDER BY u.device, u.experiment_group;


-- -----------------------------------------------------
-- Query 7: Segment uplift by device (one row per device)
-- Business question: Uplift in conversion (pp) and ARPU by device
-- -----------------------------------------------------
SELECT
  device,
  ROUND(100.0 * (treatment_conv - control_conv), 2) AS conversion_uplift_pp,
  ROUND(treatment_arpu - control_arpu, 2) AS arpu_uplift
FROM (
  SELECT
    device,
    MAX(CASE WHEN experiment_group = 'control'
        THEN converters / users END) AS control_conv,
    MAX(CASE WHEN experiment_group = 'treatment'
        THEN converters / users END) AS treatment_conv,
    MAX(CASE WHEN experiment_group = 'control'
        THEN arpu END) AS control_arpu,
    MAX(CASE WHEN experiment_group = 'treatment'
        THEN arpu END) AS treatment_arpu
  FROM (
    SELECT
      u.device,
      u.experiment_group,
      COUNT(DISTINCT u.user_id) AS users,
      COUNT(DISTINCT p.user_id) AS converters,
      SUM(COALESCE(p.amount, 0)) / COUNT(DISTINCT u.user_id) AS arpu
    FROM users u
    LEFT JOIN purchases p
      ON p.user_id = u.user_id
    GROUP BY u.device, u.experiment_group
  ) x
  GROUP BY device
) y
ORDER BY device;



