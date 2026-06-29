SELECT
    c.title,
    c.instructor,
    COUNT(e.id) AS enrollment_count,
    ROUND(AVG(e.progress_pct), 1) AS avg_progress
FROM course c
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY c.id, c.title, c.instructor
ORDER BY enrollment_count DESC, avg_progress DESC
LIMIT 10;
