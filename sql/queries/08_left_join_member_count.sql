SELECT
    m.id,
    m.nickname,
    m.tier,
    COUNT(e.id) AS enrollment_count
FROM member m
LEFT JOIN enrollment e ON m.id = e.member_id
GROUP BY m.id, m.nickname, m.tier
ORDER BY enrollment_count ASC, m.nickname;
