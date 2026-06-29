SELECT
    cat.name AS category_name,
    COUNT(e.id) AS enrollment_count
FROM category cat
LEFT JOIN course c ON cat.id = c.category_id
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY cat.id, cat.name
ORDER BY enrollment_count DESC;
