SELECT
    m.tier,
    COUNT(DISTINCT e.id) AS active_enrollment_count,
    SUM(c.price) AS total_course_price
FROM member m
INNER JOIN enrollment e ON m.id = e.member_id
INNER JOIN course c ON e.course_id = c.id
WHERE e.status IN ('ACTIVE', 'COMPLETED')
GROUP BY m.tier
ORDER BY total_course_price DESC;
