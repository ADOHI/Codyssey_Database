SELECT id, title, published_at, price
FROM course
WHERE published_at IS NOT NULL
ORDER BY published_at DESC
LIMIT 5;
