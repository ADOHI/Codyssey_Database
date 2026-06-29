SELECT
    c.id,
    cat.name AS category_name,
    c.title,
    c.instructor,
    c.price,
    c.level
FROM course c
INNER JOIN category cat ON c.category_id = cat.id
ORDER BY cat.name, c.title;
