-- ============================================================
-- Codyssey 코딩 학습 플랫폼 - 핵심 쿼리 15개
-- DB: MySQL 8.4
-- 범주: 기본조회(4+) / JOIN(4+) / 집계(3+) / 서브쿼리(1+) / UPDATE·DELETE(2+) / INDEX(1+)
-- ============================================================

USE codyssey;

-- ============================================================
-- [기본 조회 1] PRO 등급 회원 목록 조회 (WHERE)
-- 확인: 유료 PRO 회원만 필터링
-- ============================================================
SELECT id, email, nickname, tier, joined_at
FROM member
WHERE tier = 'PRO'
ORDER BY joined_at;

-- ============================================================
-- [기본 조회 2] 가격이 50,000원 이상인 강의 조회 (WHERE + ORDER BY)
-- 확인: 고가 강의를 가격 내림차순으로 정렬
-- ============================================================
SELECT id, title, instructor, price, level
FROM course
WHERE price >= 50000
ORDER BY price DESC;

-- ============================================================
-- [기본 조회 3] 최근 출간 강의 TOP 5 (ORDER BY + LIMIT)
-- 확인: published_at 기준 최신 강의 5개
-- ============================================================
SELECT id, title, published_at, price
FROM course
WHERE published_at IS NOT NULL
ORDER BY published_at DESC
LIMIT 5;

-- ============================================================
-- [기본 조회 4] 진행 중(ACTIVE) 수강 중 진도율 50% 미만 (WHERE + ORDER BY)
-- 확인: 이탈 위험 수강 건을 진도율 오름차순으로 확인
-- ============================================================
SELECT id, member_id, course_id, progress_pct, enrolled_at
FROM enrollment
WHERE status = 'ACTIVE' AND progress_pct < 50
ORDER BY progress_pct ASC, enrolled_at;

-- ============================================================
-- [INNER JOIN 1] 수강 정보 + 회원 닉네임 + 강의 제목
-- 확인: enrollment를 member, course와 연결한 상세 목록
-- ============================================================
SELECT
    e.id AS enrollment_id,
    m.nickname,
    c.title AS course_title,
    e.progress_pct,
    e.status,
    e.enrolled_at
FROM enrollment e
INNER JOIN member m ON e.member_id = m.id
INNER JOIN course c ON e.course_id = c.id
ORDER BY e.enrolled_at DESC;

-- ============================================================
-- [INNER JOIN 2] 강의 + 카테고리명 + 강사명
-- 확인: course와 category 1:N 관계 조인
-- ============================================================
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

-- ============================================================
-- [INNER JOIN 3] 완료(COMPLETED) 수강 + 회원 이메일 + 강의 가격
-- 확인: 수료 완료 건과 결제 금액(강의 가격) 연결
-- ============================================================
SELECT
    m.email,
    c.title,
    c.price,
    e.enrolled_at,
    e.progress_pct
FROM enrollment e
INNER JOIN member m ON e.member_id = m.id
INNER JOIN course c ON e.course_id = c.id
WHERE e.status = 'COMPLETED'
ORDER BY e.enrolled_at;

-- ============================================================
-- [LEFT JOIN 1] 모든 회원 + 수강 건수 (수강 없는 회원 포함)
-- 확인: LEFT JOIN으로 0건 회원도 표시
-- ============================================================
SELECT
    m.id,
    m.nickname,
    m.tier,
    COUNT(e.id) AS enrollment_count
FROM member m
LEFT JOIN enrollment e ON m.id = e.member_id
GROUP BY m.id, m.nickname, m.tier
ORDER BY enrollment_count ASC, m.nickname;

-- ============================================================
-- [LEFT JOIN 2] 모든 강의 + 수강 신청 건수 (미수강 강의 포함)
-- 확인: 인기 없는 강의(0건) 식별
-- ============================================================
SELECT
    c.id,
    c.title,
    cat.name AS category_name,
    COUNT(e.id) AS enrollment_count
FROM course c
INNER JOIN category cat ON c.category_id = cat.id
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY c.id, c.title, cat.name
ORDER BY enrollment_count DESC, c.title;

-- ============================================================
-- [집계 1] 강의별 수강 신청 건수 (COUNT + GROUP BY)
-- 확인: 가장 인기 있는 강의 TOP 10
-- ============================================================
SELECT
    c.title,
    COUNT(e.id) AS total_enrollments
FROM course c
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY c.id, c.title
ORDER BY total_enrollments DESC
LIMIT 10;

-- ============================================================
-- [집계 2] 카테고리별 평균 수강 진도율 (AVG + GROUP BY)
-- 확인: 카테고리별 학습 완료도 비교
-- ============================================================
SELECT
    cat.name AS category_name,
    ROUND(AVG(e.progress_pct), 1) AS avg_progress_pct,
    COUNT(e.id) AS enrollment_count
FROM category cat
INNER JOIN course c ON cat.id = c.category_id
INNER JOIN enrollment e ON c.id = e.course_id
GROUP BY cat.id, cat.name
HAVING enrollment_count > 0
ORDER BY avg_progress_pct DESC;

-- ============================================================
-- [집계 3] 회원 등급별 수강 중 강의 가격 합계 (SUM + COUNT + GROUP BY)
-- 확인: tier별 학습 투자(등록 강의 가격 합) 비교
-- ============================================================
SELECT
    m.tier,
    COUNT(DISTINCT e.id) AS active_enrollment_count,
    SUM(c.price) AS total_course_price
FROM member m
INNER JOIN enrollment e ON m.id = e.member_id
INNER JOIN course c ON e.course_id = c.id
WHERE e.status IN ('ACTIVE', 'COMPLETED')
GROUP BY m.tier
ORDER BY total_course_price DESC;

-- ============================================================
-- [서브쿼리 1] 한 번도 수강 신청하지 않은 회원 (NOT IN 서브쿼리)
-- 확인: 마케팅 대상(미수강) 회원 목록
-- ============================================================
SELECT id, email, nickname, joined_at
FROM member
WHERE id NOT IN (
    SELECT DISTINCT member_id
    FROM enrollment
)
ORDER BY joined_at;

-- ============================================================
-- [UPDATE 1] 진도율 100%인데 ACTIVE인 수강을 COMPLETED로 변경
-- 확인: 데이터 정합성 보정 (수료 상태 자동 반영)
-- ============================================================
UPDATE enrollment
SET status = 'COMPLETED'
WHERE progress_pct = 100
  AND status = 'ACTIVE';

-- ============================================================
-- [DELETE 1] 취소(CANCELLED) 상태 수강 기록 삭제
-- 확인: 불필요한 취소 이력 정리
-- ============================================================
DELETE FROM enrollment
WHERE status = 'CANCELLED';

-- ============================================================
-- [INDEX 1] enrollment.enrolled_at 인덱스 생성
-- 이유: "최근 N일 수강", "기간별 수강 추이" 조회 시 enrolled_at 범위 검색이 잦음
-- ============================================================
CREATE INDEX idx_enrollment_enrolled_at ON enrollment (enrolled_at);

-- 인덱스 적용 확인 (MySQL 전용: SHOW INDEX)
SHOW INDEX FROM enrollment WHERE Key_name = 'idx_enrollment_enrolled_at';

-- ============================================================
-- [보너스] JOIN vs 서브쿼리 비교 - 평균 수강 건수 이상인 강의
-- ============================================================

-- JOIN + GROUP BY + HAVING 방식
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

-- 상관 서브쿼리 방식 (동일 요구)
SELECT title, (
    SELECT COUNT(*)
    FROM enrollment e
    WHERE e.course_id = c.id
) AS cnt
FROM course c
HAVING cnt >= (
    SELECT AVG(course_cnt)
    FROM (
        SELECT COUNT(*) AS course_cnt
        FROM enrollment
        GROUP BY course_id
    ) AS sub
);
