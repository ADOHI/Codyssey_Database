SELECT id, email, nickname, joined_at
FROM member
WHERE id NOT IN (
    SELECT DISTINCT member_id
    FROM enrollment
)
ORDER BY joined_at;
