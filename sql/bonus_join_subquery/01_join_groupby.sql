SELECT c.title, COUNT(e.id) AS cnt
FROM course c
INNER JOIN enrollment e ON c.id = e.course_id
GROUP BY c.id, c.title
HAVING COUNT(e.id) >= (
    SELECT AVG(course_cnt)
    FROM (
        SELECT COUNT(*) AS course_cnt
        FROM enrollment
        GROUP BY course_id
    ) AS sub
);
