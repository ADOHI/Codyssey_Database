SELECT
    e.id AS enrollment_id,
    m.nickname,
    c.title AS course_title,
    e.progress_pct,
    e.status,
    e.enrolled_at
FROM enrollment e
INNER JOIN member m ON e.member_id = m.id
INNER JOIN course c ON e.course_id = c.id
ORDER BY e.enrolled_at DESC;
