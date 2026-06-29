-- ============================================================
-- [보너스] FK 제약 위반 테스트 - 의도적으로 실패시키기
-- 실행하면 에러가 나야 정상 (FK가 동작함을 증명)
-- ============================================================

USE codyssey;

-- 1) 존재하지 않는 member_id 참조 → FK 에러 예상
-- ERROR 1452: Cannot add or update a child row: a foreign key constraint fails
INSERT INTO enrollment (member_id, course_id, enrolled_at, progress_pct, status)
VALUES (9999, 1, NOW(), 0, 'ACTIVE');

-- 2) 존재하지 않는 course_id 참조 → FK 에러 예상
INSERT INTO enrollment (member_id, course_id, enrolled_at, progress_pct, status)
VALUES (1, 9999, NOW(), 0, 'ACTIVE');

-- 해결 방법:
-- - member_id / course_id에 실제로 존재하는 PK 값을 사용한다.
-- - 또는 먼저 member / course 테이블에 부모 행을 INSERT한 뒤 enrollment를 넣는다.
