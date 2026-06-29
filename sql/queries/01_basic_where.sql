SELECT id, email, nickname, tier, joined_at
FROM member
WHERE tier = 'PRO'
ORDER BY joined_at;
