DELETE FROM enrollment
WHERE status = 'CANCELLED';

SELECT ROW_COUNT() AS deleted_rows;
