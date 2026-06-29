SELECT
    m.email,
    c.title,
    c.price,
    e.enrolled_at,
    e.progress_pct
FROM enrollment e
INNER JOIN member m ON e.member_id = m.id
INNER JOIN course c ON e.course_id = c.id
WHERE e.status = 'COMPLETED'
ORDER BY e.enrolled_at;
