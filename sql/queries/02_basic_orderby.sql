SELECT id, title, instructor, price, level
FROM course
WHERE price >= 50000
ORDER BY price DESC;
