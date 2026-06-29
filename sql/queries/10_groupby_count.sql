SELECT
    c.title,
    COUNT(e.id) AS total_enrollments
FROM course c
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY c.id, c.title
ORDER BY total_enrollments DESC
LIMIT 10;
