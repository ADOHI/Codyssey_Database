SELECT
    cat.name AS category_name,
    ROUND(AVG(e.progress_pct), 1) AS avg_progress_pct,
    COUNT(e.id) AS enrollment_count
FROM category cat
INNER JOIN course c ON cat.id = c.category_id
INNER JOIN enrollment e ON c.id = e.course_id
GROUP BY cat.id, cat.name
HAVING enrollment_count > 0
ORDER BY avg_progress_pct DESC;
