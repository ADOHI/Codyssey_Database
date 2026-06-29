SELECT title, (
    SELECT COUNT(*)
    FROM enrollment e
    WHERE e.course_id = c.id
) AS cnt
FROM course c
HAVING cnt >= (
    SELECT AVG(course_cnt)
    FROM (
        SELECT COUNT(*) AS course_cnt
        FROM enrollment
        GROUP BY course_id
    ) AS sub
);
