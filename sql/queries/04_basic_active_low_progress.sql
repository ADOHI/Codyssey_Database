SELECT id, member_id, course_id, progress_pct, enrolled_at
FROM enrollment
WHERE status = 'ACTIVE' AND progress_pct < 50
ORDER BY progress_pct ASC, enrolled_at;
