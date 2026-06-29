-- ============================================================
-- Codyssey 코딩 학습 플랫폼 - 샘플 데이터 입력
-- FK 참조 순서: category → member → course → enrollment
-- 각 테이블 10행 이상
-- ============================================================

USE codyssey;

-- ------------------------------------------------------------
-- category (12행)
-- ------------------------------------------------------------
INSERT INTO category (name, description) VALUES
('Backend',    '서버·API·데이터베이스 중심 강의'),
('Frontend',   '웹 UI·React·CSS 중심 강의'),
('DevOps',     '배포·인프라·CI/CD 강의'),
('Mobile',     'Android·iOS·크로스플랫폼 강의'),
('Data',       'SQL·분석·머신러닝 입문 강의'),
('Security',   '보안·인증·취약점 대응 강의'),
('Game',       'Unity·게임 로직·그래픽스 강의'),
('AI',         'LLM·프롬프트·AI 앱 개발 강의'),
('Cloud',      'AWS·GCP·클라우드 아키텍처 강의'),
('Career',     '포트폴리오·이력서·면접 준비 강의'),
('OpenSource', '기여·협업·Git 워크플로우 강의'),
('Design',     'UX·UI·프로토타이핑 강의');

-- ------------------------------------------------------------
-- member (12행)
-- ------------------------------------------------------------
INSERT INTO member (email, nickname, tier, joined_at) VALUES
('kim@example.com',      'kim_dev',       'PRO',          '2024-01-15'),
('lee@example.com',      'lee_coder',     'FREE',         '2024-02-20'),
('park@example.com',     'park_sql',      'PRO',          '2024-03-10'),
('choi@example.com',     'choi_java',     'FREE',         '2024-04-05'),
('jung@example.com',     'jung_react',    'ENTERPRISE',   '2024-05-18'),
('han@example.com',      'han_data',      'PRO',          '2024-06-22'),
('yoon@example.com',     'yoon_newbie',   'FREE',         '2024-07-01'),
('kang@example.com',     'kang_ops',      'PRO',          '2024-08-14'),
('shin@example.com',     'shin_mobile',   'FREE',         '2024-09-09'),
('oh@example.com',       'oh_security',   'ENTERPRISE',   '2024-10-30'),
('lim@example.com',      'lim_ai',        'PRO',          '2024-11-11'),
('bae@example.com',      'bae_guest',     'FREE',         '2025-01-08');

-- ------------------------------------------------------------
-- course (14행) - category_id FK 참조
-- ------------------------------------------------------------
INSERT INTO course (category_id, title, instructor, price, level, published_at) VALUES
(1,  'Spring Boot REST API 마스터',        '김백엔', 89000,  'INTERMEDIATE', '2024-02-01'),
(1,  'JPA와 Hibernate 실전',               '이영속', 79000,  'ADVANCED',     '2024-03-15'),
(2,  'React로 Todo 앱 만들기',               '박프론', 59000,  'BEGINNER',     '2024-01-20'),
(2,  'TypeScript 핵심 문법',                 '최타입', 49000,  'BEGINNER',     '2024-04-10'),
(3,  'Docker와 Kubernetes 입문',             '정데브옵',99000,  'INTERMEDIATE', '2024-05-01'),
(4,  'Flutter 크로스플랫폼 앱',              '한모바', 69000,  'INTERMEDIATE', '2024-06-12'),
(5,  'SQL과 데이터 모델링 기초',             '윤데이터',39000,  'BEGINNER',     '2024-02-28'),
(5,  'MySQL 실무 쿼리 200선',                '강쿼리', 59000,  'INTERMEDIATE', '2024-07-20'),
(6,  '웹 보안 OWASP Top 10',                 '신시큐', 79000,  'ADVANCED',     '2024-08-05'),
(7,  'Unity 2D 게임 제작',                   '오게임', 89000,  'BEGINNER',     '2024-09-18'),
(8,  'ChatGPT API로 AI 서비스 만들기',       '임AI',   99000,  'INTERMEDIATE', '2024-10-22'),
(9,  'AWS EC2와 RDS 배포 실습',              '배클라', 109000, 'INTERMEDIATE', '2024-11-05'),
(10, '개발자 포트폴리오 완성하기',           '김커리', 29000,  'BEGINNER',     '2024-12-01'),
(11, '오픈소스 첫 기여 가이드',              '이깃',   0,      'BEGINNER',     '2025-01-15');

-- ------------------------------------------------------------
-- enrollment (18행) - member_id, course_id FK 참조
-- ------------------------------------------------------------
INSERT INTO enrollment (member_id, course_id, enrolled_at, progress_pct, status) VALUES
(1,  1,  '2024-03-01 09:00:00', 100, 'COMPLETED'),
(1,  7,  '2024-03-15 10:30:00', 85,  'ACTIVE'),
(2,  3,  '2024-03-20 14:00:00', 60,  'ACTIVE'),
(2,  4,  '2024-04-01 11:00:00', 40,  'ACTIVE'),
(3,  7,  '2024-04-10 09:30:00', 100, 'COMPLETED'),
(3,  8,  '2024-05-01 16:00:00', 70,  'ACTIVE'),
(4,  1,  '2024-05-05 13:00:00', 30,  'ACTIVE'),
(5,  5,  '2024-06-01 10:00:00', 100, 'COMPLETED'),
(5,  12, '2024-06-20 15:30:00', 55,  'ACTIVE'),
(6,  7,  '2024-07-05 09:00:00', 100,  'ACTIVE'),
(6,  8,  '2024-07-20 11:00:00', 90,  'ACTIVE'),
(7,  3,  '2024-08-01 12:00:00', 15,  'ACTIVE'),
(8,  5,  '2024-08-15 08:30:00', 45,  'ACTIVE'),
(8,  6,  '2024-09-01 17:00:00', 20,  'CANCELLED'),
(9,  9,  '2024-09-10 10:00:00', 100, 'COMPLETED'),
(10, 11, '2024-10-05 14:00:00', 75,  'ACTIVE'),
(11, 11, '2024-11-01 09:00:00', 50,  'ACTIVE'),
(11, 13, '2024-12-10 13:30:00', 100, 'COMPLETED');
