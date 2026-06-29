-- ============================================================
-- [보너스] 핵심 지표 3개 - 미니 리포트
-- ============================================================

USE codyssey;

-- 지표 1: 카테고리별 수강 신청 건수 (인기 카테고리)
SELECT
    cat.name AS category_name,
    COUNT(e.id) AS enrollment_count
FROM category cat
LEFT JOIN course c ON cat.id = c.category_id
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY cat.id, cat.name
ORDER BY enrollment_count DESC;

-- 지표 2: 강의별 수강 TOP 10 + 평균 진도율 (베스트셀러)
SELECT
    c.title,
    c.instructor,
    COUNT(e.id) AS enrollment_count,
    ROUND(AVG(e.progress_pct), 1) AS avg_progress
FROM course c
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY c.id, c.title, c.instructor
ORDER BY enrollment_count DESC, avg_progress DESC
LIMIT 10;

-- 지표 3: PRO 회원 평균 수강 진도율 (유료 회원 참여도)
SELECT
    m.tier,
    COUNT(e.id) AS enrollment_count,
    ROUND(AVG(e.progress_pct), 1) AS avg_progress_pct
FROM member m
LEFT JOIN enrollment e ON m.id = e.member_id
WHERE m.tier = 'PRO'
GROUP BY m.tier;
