UPDATE enrollment
SET status = 'COMPLETED'
WHERE progress_pct = 100
  AND status = 'ACTIVE';

SELECT ROW_COUNT() AS affected_rows;
