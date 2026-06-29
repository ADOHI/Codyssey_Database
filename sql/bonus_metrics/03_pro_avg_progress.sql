SELECT
    m.tier,
    COUNT(e.id) AS enrollment_count,
    ROUND(AVG(e.progress_pct), 1) AS avg_progress_pct
FROM member m
LEFT JOIN enrollment e ON m.id = e.member_id
WHERE m.tier = 'PRO'
GROUP BY m.tier;
