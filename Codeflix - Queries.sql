--For this project, we will learn to calculate churn rates with SQL for a monthly subscription service.  
 
 /* Get familiar with the data */
 SELECT *
 FROM subscriptions 
 LIMIT 100;

  SELECT 
    MIN(subscription_start), 
    MAX(subscription_start)
 FROM subscriptions;

/* ----------------------------------------------- */
/* Calculate churn rate for each segment */

-- a) Create a temporary table called 'months.'
WITH months AS  
(SELECT
  '2017-01-01' AS first_day,
  '2017-01-31' AS last_day
UNION
SELECT
  '2017-02-01' AS first_day,
  '2017-02-28' AS last_day
UNION
SELECT
  '2017-03-01' AS first_day,
  '2017-03-31' AS last_day
),

-- b) Create a temporary table called 'cross_join, from 'subscriptions' and the 'months' tables.
cross_join AS
(SELECT *
FROM subscriptions
CROSS JOIN months
),

-- c) Create a temporary table called 'status' from the 'cross_join' table.
  -- Create a column 'is_active_87' to find any users from segment 87 who existed prior to the beginning of the month. This is 1 if true and 0 otherwise. Then do the same for segment 30.
  -- Create a column 'is_canceled_87' and 'is_canceled_30'. This should be 1 if the subscription is canceled during the month and 0 otherwise. 
status AS
(SELECT id,
    first_day AS 'month',
    CASE
      WHEN segment = 87
        AND subscription_start < first_day
        AND (
          subscription_end > first_day
          OR subscription_end IS NULL
        ) THEN 1
      ELSE 0
    END AS 'is_active_87',
    CASE
      WHEN segment = 30 
        AND subscription_start < first_day
        AND (
          subscription_end > first_day
          OR subscription_end IS NULL
        ) THEN 1
      ELSE 0
    END AS 'is_active_30',
    CASE
      WHEN segment = 87
        AND subscription_end BETWEEN first_day AND last_day THEN 1
      ELSE 0
    END AS 'is_canceled_87',
    CASE
      WHEN segment = 30
        AND subscription_end BETWEEN first_day AND last_day THEN 1
      ELSE 0
    END AS 'is_canceled_30' 
FROM cross_join
),

-- d) Create a temporary table called 'status_aggregate' that is the SUM of the active and canceled subscriptions for each segment and each month.
status_aggregate AS
(SELECT month,
    SUM(is_active_87) AS 'sum_active_87',
    SUM(is_active_30) AS 'sum_active_30',
    SUM(is_canceled_87) AS 'sum_canceled_87',
    SUM(is_canceled_30) AS 'sum_canceled_30'
  FROM status
  GROUP BY 1)

-- e) Calculate the churn rates for the two segments over the three month period.
SELECT month, sum_active_87, sum_active_30, 
  sum_canceled_87, sum_canceled_30,
  1.0 * sum_canceled_87 / sum_active_87 AS 'churn_rate_87',
  1.0 * sum_canceled_30 / sum_active_30 AS 'churn_rate_30'
FROM status_aggregate;


/* BONUS: Modify the code to support a large number of segments. */

WITH months AS  
(SELECT
  '2017-01-01' AS first_day,
  '2017-01-31' AS last_day
UNION
SELECT
  '2017-02-01' AS first_day,
  '2017-02-28' AS last_day
UNION
SELECT
  '2017-03-01' AS first_day,
  '2017-03-31' AS last_day
),
cross_join AS
(SELECT *
FROM subscriptions
CROSS JOIN months
),

--Create a temporary table called 'status' from the 'cross_join' table.
--Remove hardcoding of the segment numbers. 
status AS
(SELECT id, segment,
    first_day AS 'month',
    CASE
      WHEN subscription_start < first_day
        AND (
          subscription_end > first_day
          OR subscription_end IS NULL
        ) THEN 1
      ELSE 0
    END AS 'is_active',
    CASE
      WHEN subscription_end BETWEEN first_day AND last_day THEN 1
      ELSE 0
    END AS 'is_canceled' 
FROM cross_join
),

--Create a temporary table called 'status_aggregate' that is the SUM of the active and canceled subscriptions for each month.
status_aggregate AS
(SELECT month,
    segment,
    SUM(is_active) AS 'sum_active',
    SUM(is_canceled) AS 'sum_canceled'
  FROM status
  GROUP BY 1, 2)

--Calculate the churn rates for each segment over the three month period.
SELECT month, segment,
  1.0 * sum_canceled / sum_active AS 'churn_rate'
FROM status_aggregate
ORDER BY 2, 1;

/* ----------------------------------------------- */
/* Calculate Overall Churn Trend */
-- Use the BONUS modified code above, but 

WITH months AS  
(SELECT
  '2017-01-01' AS first_day,
  '2017-01-31' AS last_day
UNION
SELECT
  '2017-02-01' AS first_day,
  '2017-02-28' AS last_day
UNION
SELECT
  '2017-03-01' AS first_day,
  '2017-03-31' AS last_day
),
cross_join AS
(SELECT *
FROM subscriptions
CROSS JOIN months
),
status AS
(SELECT id, segment,
    first_day AS 'month',
    CASE
      WHEN subscription_start < first_day
        AND (
          subscription_end > first_day
          OR subscription_end IS NULL
        ) THEN 1
      ELSE 0
    END AS 'is_active',
    CASE
      WHEN subscription_end BETWEEN first_day AND last_day THEN 1
      ELSE 0
    END AS 'is_canceled' 
FROM cross_join
),
status_aggregate AS
(SELECT month,
    segment,
    SUM(is_active) AS 'sum_active',
    SUM(is_canceled) AS 'sum_canceled'
  FROM status
  GROUP BY 1)

--Calculate the total churn rates over the three month period.
SELECT month, sum_active, sum_canceled,
  1.0 * sum_canceled / sum_active AS 'churn_rate'
FROM status_aggregate
GROUP BY 1
ORDER BY 1;

