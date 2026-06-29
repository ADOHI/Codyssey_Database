SELECT
    c.id,
    c.title,
    cat.name AS category_name,
    COUNT(e.id) AS enrollment_count
FROM course c
INNER JOIN category cat ON c.category_id = cat.id
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY c.id, c.title, cat.name
ORDER BY enrollment_count DESC, c.title;
