# DB & SQL 과제 예상 Q&A

> **프로젝트:** Codyssey 코딩 학습 플랫폼  
> **DB:** MySQL 8.4 (Docker)  
> **테이블:** `category`, `member`, `course`, `enrollment`

---

## 목차

1. [데이터베이스 기본 개념](#1-데이터베이스-기본-개념)
2. [데이터 모델링 & 관계](#2-데이터-모델링--관계)
3. [제약조건 & 무결성](#3-제약조건--무결성)
4. [SQL 기본 (CRUD)](#4-sql-기본-crud)
5. [JOIN](#5-join)
6. [집계 & GROUP BY](#6-집계--group-by)
7. [서브쿼리](#7-서브쿼리)
8. [인덱스](#8-인덱스)
9. [과제 제출물 관련](#9-과제-제출물-관련)
10. [본 프로젝트(Codyssey) 관련](#10-본-프로젝트codyssey-관련)
11. [개발 환경 (Docker / MySQL)](#11-개발-환경-docker--mysql)
12. [ORM / JPA 연결](#12-orm--jpa-연결)
13. [보너스 과제 관련](#13-보너스-과제-관련)

---

## 1. 데이터베이스 기본 개념

### Q1. 엑셀과 DB의 차이는 뭔가요?

**A.** 차이는 "데이터 양"이 아니라 **구조와 규칙**입니다.

| | 엑셀 | DB |
|---|------|-----|
| 관계 표현 | 시트/열을 사람이 연결 | FK로 테이블 간 관계를 **강제** |
| 중복 방지 | 수동 관리 | UNIQUE, PK 등 **제약조건**으로 방지 |
| 동시 접근 | 충돌 위험 큼 | 트랜잭션으로 **안전하게** 처리 |
| 대용량 | 느려짐 | 인덱스·최적화로 **대규모** 처리 가능 |

엑셀은 "표를 그리는 도구"이고, DB는 "데이터를 규칙과 관계로 안전하게 저장·조회하는 시스템"입니다.

---

### Q2. 왜 테이블을 나눠서 저장하나요?

**A.** **중복을 줄이고, 수정을 한 곳에서** 하기 위해서입니다.

예를 들어 강의 카테고리를 `course` 테이블마다 문자열로 반복 저장하면:
- 카테고리명 변경 시 모든 행을 수정해야 함
- 오타·불일치 발생 (`Backend` vs `backend`)

`category` 테이블을 분리하고 `course.category_id`로 FK 연결하면, 카테고리명은 **한 곳만** 수정하면 됩니다. 이것이 **정규화**의 기본 아이디어입니다.

---

### Q3. RDBMS란?

**A.** **Relational Database Management System** — 관계형 데이터베이스 관리 시스템입니다.  
데이터를 **테이블(행·열)** 형태로 저장하고, **SQL**로 조회·수정합니다.  
MySQL, PostgreSQL, SQLite, Oracle 등이 대표적입니다.

---

### Q4. SQL이란?

**A.** **Structured Query Language** — 관계형 DB에서 데이터를 **정의(DDL)**, **조작(DML)**, **조회(DQL)** 하는 표준 언어입니다.  
백엔드 없이도 DB에 직접 요구사항(검색, 정렬, 집계)을 해결할 수 있습니다.

---

## 2. 데이터 모델링 & 관계

### Q5. PK(Primary Key)란?

**A.** 테이블에서 **각 행을 유일하게 식별**하는 컬럼(또는 컬럼 조합)입니다.

- NULL 불가
- 중복 불가
- 보통 `id INT AUTO_INCREMENT` 형태

예: `member.id = 3`이면 "park_sql 회원" 한 명만 가리킵니다.

---

### Q6. FK(Foreign Key)란?

**A.** **다른 테이블의 PK를 참조**하는 컬럼입니다. 테이블 간 **관계**를 DB 수준에서 연결합니다.

예 (본 프로젝트):
```sql
enrollment.member_id → member.id
enrollment.course_id → course.id
course.category_id   → category.id
```

FK가 있으면 **존재하지 않는 부모 ID**로 자식 행을 넣을 수 없습니다.

---

### Q7. 1:N 관계란?

**A.** **하나의 부모**에 **여러 자식**이 연결되는 관계입니다.

| 관계 | 부모 (1) | 자식 (N) |
|------|----------|----------|
| 카테고리 → 강의 | `category` | `course` |
| 회원 → 수강 | `member` | `enrollment` |
| 강의 → 수강 | `course` | `enrollment` |

FK는 **항상 N쪽(자식) 테이블**에 둡니다.

---

### Q8. N:M(다대다) 관계는 어떻게 표현하나?

**A.** **중간 테이블( junction / bridge )** 을 둡니다.

본 프로젝트에서 `member` ↔ `course`는 직접 N:M이지만, `enrollment`가 중간 역할을 합니다.

```
member (1) ──< enrollment >── (1) course
```

한 회원이 여러 강의를, 한 강의에 여러 회원이 수강 → N:M  
`enrollment`에 `(member_id, course_id)` UNIQUE로 중복 수강 방지.

---

### Q9. ERD란?

**A.** **Entity Relationship Diagram** — 테이블(엔티티)과 관계(FK)를 **그림**으로 표현한 다이어그램입니다.  
스키마 구조를 한눈에 파악하고, 설계·발표·문서화에 사용합니다.  
본 프로젝트는 `erd.dbml` → [dbdiagram.io](https://dbdiagram.io)에서 시각화 가능.

---

## 3. 제약조건 & 무결성

### Q10. NOT NULL, UNIQUE, CHECK 차이는?

**A.**

| 제약 | 의미 | 본 프로젝트 예시 |
|------|------|------------------|
| **NOT NULL** | 빈 값 금지 | `member.email NOT NULL` |
| **UNIQUE** | 중복 값 금지 | `member.email UNIQUE`, `(member_id, course_id) UNIQUE` |
| **CHECK** | 조건 검사 | `progress_pct BETWEEN 0 AND 100`, `tier IN ('FREE','PRO','ENTERPRISE')` |
| **FK** | 참조 무결성 | `member_id`는 `member.id`에 반드시 존재 |

---

### Q11. FK 에러(ERROR 1452)가 나는 이유는?

**A.** 자식 테이블이 **존재하지 않는 부모 PK**를 참조하려 할 때 발생합니다.

```sql
-- member.id = 9999 는 없음 → FK 위반
INSERT INTO enrollment (member_id, course_id, ...)
VALUES (9999, 1, ...);
```

**해결:** 부모 테이블에 해당 ID가 있는지 확인 후 INSERT.  
INSERT 순서: `category` → `member` → `course` → `enrollment`

---

### Q12. ON DELETE RESTRICT / ON UPDATE CASCADE 란?

**A.**

- **RESTRICT:** 부모 행을 삭제/변경하려 할 때, **자식이 있으면 막음**
- **CASCADE:** 부모 PK 변경 시 **자식 FK도 함께** 갱신 (UPDATE CASCADE)

본 프로젝트는 `ON DELETE RESTRICT` — 회원/강의를 함부로 삭제하지 못하게 보호합니다.

---

### Q13. 데이터 무결성이란?

**A.** DB 데이터가 **항상 규칙과 관계에 맞게** 유지되는 상태입니다.

- **개체 무결성:** PK 유일·NOT NULL
- **참조 무결성:** FK가 실제 존재하는 값만 참조
- **도메인 무결성:** CHECK, 타입 등 값 범위 준수

---

## 4. SQL 기본 (CRUD)

### Q14. SELECT / INSERT / UPDATE / DELETE 차이?

**A.**

| 명령 | 용도 | 언제 쓰나 |
|------|------|-----------|
| **SELECT** | 조회 | 데이터 확인, 리포트, 검색 |
| **INSERT** | 삽입 | 새 회원, 새 수강 등록 |
| **UPDATE** | 수정 | 진도율 변경, 상태 COMPLETED 처리 |
| **DELETE** | 삭제 | 취소된 수강 기록 정리 |

**SELECT**는 데이터를 바꾸지 않음. **UPDATE/DELETE**는 실제 데이터가 변경되므로 WHERE 조건을 꼭 확인.

---

### Q15. WHERE, ORDER BY, LIMIT 역할은?

**A.**

- **WHERE:** 조건 필터 (`tier = 'PRO'`, `price >= 50000`)
- **ORDER BY:** 정렬 (`ORDER BY price DESC`)
- **LIMIT:** 결과 개수 제한 (`LIMIT 5` → TOP 5)

---

### Q16. INSERT 순서가 왜 중요한가?

**A.** FK 때문에 **부모 테이블 데이터가 먼저** 있어야 합니다.

```
1. category  (FK 없음)
2. member    (FK 없음)
3. course    (category_id 참조)
4. enrollment (member_id, course_id 참조)
```

---

## 5. JOIN

### Q17. JOIN이란?

**A.** **FK로 연결된 여러 테이블**의 데이터를 **한 결과 집합**으로 합치는 것입니다.  
"회원 이름 + 수강한 강의 제목"처럼 여러 테이블 정보를 한 번에 보려면 JOIN이 필요합니다.

---

### Q18. INNER JOIN vs LEFT JOIN 차이?

**A.**

| | INNER JOIN | LEFT JOIN |
|---|------------|-----------|
| 결과 | **양쪽 모두 매칭**되는 행만 | **왼쪽 테이블 전부** + 오른쪽 매칭 |
| 매칭 없을 때 | 제외 | 왼쪽은 나오고, 오른쪽은 NULL |

**예시 (본 프로젝트):**
- INNER JOIN: 수강 기록이 **있는** 회원+강의만
- LEFT JOIN: **모든 회원** + 수강 건수 (0건도 포함 → `bae_guest`처럼 미수강 회원 찾기)

---

### Q19. JOIN을 여러 개 쓸 수 있나?

**A.** 네. 본 프로젝트 쿼리 5번처럼 3테이블 JOIN 가능합니다.

```sql
FROM enrollment e
INNER JOIN member m ON e.member_id = m.id
INNER JOIN course c ON e.course_id = c.id
```

---

## 6. 집계 & GROUP BY

### Q20. GROUP BY란?

**A.** 특정 컬럼 기준으로 **행을 묶어서** 집계 함수(COUNT, SUM, AVG 등)를 적용합니다.

```sql
-- 강의별 수강 신청 건수
SELECT c.title, COUNT(e.id) AS total
FROM course c
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY c.id, c.title;
```

---

### Q21. COUNT / SUM / AVG 차이?

**A.**

| 함수 | 의미 | 예시 |
|------|------|------|
| **COUNT** | 행 개수 | 강의별 수강 건수 |
| **SUM** | 합계 | tier별 수강 강의 가격 합 |
| **AVG** | 평균 | 카테고리별 평균 진도율 |

---

### Q22. HAVING vs WHERE 차이?

**A.**

- **WHERE:** GROUP BY **전** — 개별 행 필터
- **HAVING:** GROUP BY **후** — 그룹 단위 필터

```sql
GROUP BY cat.name
HAVING enrollment_count > 0   -- 집계 후 조건
```

---

## 7. 서브쿼리

### Q23. 서브쿼리란?

**A.** SQL **안에 또 다른 SELECT**를 넣는 방식입니다.

```sql
-- 수강 신청 없는 회원
SELECT id, email, nickname
FROM member
WHERE id NOT IN (
    SELECT DISTINCT member_id FROM enrollment
);
```

---

### Q24. JOIN vs 서브쿼리, 언제 뭘 쓰나?

**A.**

| | JOIN | 서브쿼리 |
|---|------|----------|
| 가독성 | 관계가 명확할 때 유리 | "존재 여부" 체크에 직관적 |
| 성능 | 대체로 JOIN이 유리한 경우 많음 | 데이터·DB에 따라 다름 |
| 용도 | 여러 테이블 컬럼 동시 출력 | 필터링, EXISTS/NOT IN |

같은 요구를 두 방식으로 풀어보고 **결과가 같은지** 비교하는 것이 보너스 과제 목표입니다.

---

## 8. 인덱스

### Q25. 인덱스란? 왜 필요한가?

**A.** DB가 데이터를 **빠르게 찾기 위한 색인(목차)** 입니다.  
책의 목차 없이 전 페이지를 넘기는 것 = **Full Table Scan**  
인덱스가 있으면 해당 컬럼 검색·정렬·JOIN이 **훨씬 빨라질 수** 있습니다.

---

### Q26. 어떤 컬럼에 인덱스를 거나?

**A.** 다음 조건에 해당하면 후보입니다.

- **WHERE**에 자주 쓰이는 컬럼 (`enrolled_at`, `member_id`)
- **JOIN** 키 (FK 컬럼 — InnoDB는 FK에 자동 인덱스 생성)
- **ORDER BY**에 자주 쓰이는 컬럼
- **카�.cardinality(고유값)** 가 높은 컬럼

본 프로젝트: `CREATE INDEX idx_enrollment_enrolled_at ON enrollment (enrolled_at)`  
→ "최근 N일 수강", 기간별 추이 조회에 유리.

---

### Q27. 인덱스 단점은?

**A.**

- INSERT/UPDATE/DELETE 시 인덱스도 **갱신**해야 해서 쓰기가 느려질 수 있음
- 디스크 **추가 공간** 사용
- **모든 컬럼**에 거는 것은 비효율

---

## 9. 과제 제출물 관련

### Q28. 제출해야 하는 파일은?

**A.**

| 파일 | 내용 |
|------|------|
| `01_schema.sql` | CREATE TABLE, PK/FK/제약조건 |
| `02_insert_sample_data.sql` | INSERT 샘플 (테이블당 10행+) |
| `03_queries.sql` | 핵심 쿼리 15개+ |
| `results/` | 각 쿼리 실행 결과 (텍스트 또는 스크린샷) |
| (선택) ERD | `erd.dbml` 또는 이미지 |

---

### Q29. 최소 4개 테이블, 1:N 2개 이상 — 본 프로젝트는?

**A.**

**테이블 4개:** `category`, `member`, `course`, `enrollment`

**1:N 3개:**
1. `category` → `course`
2. `member` → `enrollment`
3. `course` → `enrollment`

---

### Q30. 쿼리 15개 범주별로 몇 개씩?

**A.**

| 범주 | 최소 | 본 프로젝트 |
|------|------|-------------|
| 기본 조회 (WHERE/ORDER BY/LIMIT) | 4 | #1~4 |
| JOIN (INNER 2+, LEFT 1+) | 4 | #5~9 |
| 집계 (COUNT/SUM/AVG + GROUP BY) | 3 | #10~12 |
| 서브쿼리 | 1 | #13 |
| UPDATE / DELETE | 2 | #14~15 |
| INDEX | 1 | #16 |

---

### Q31. 백엔드 프레임워크 써도 되나?

**A.** **안 됩니다.** Spring, Django, Express 등으로 API/화면을 만들지 않고, **순수 SQL**만으로 제출합니다.

---

### Q32. View, 프로시저, 트리거 써도 되나?

**A.** 과제 범위 **밖**입니다. CREATE TABLE + INSERT + SELECT/JOIN/GROUP BY/UPDATE/DELETE/INDEX 범위 내에서 작성합니다.

---

## 10. 본 프로젝트(Codyssey) 관련

### Q33. 왜 "코딩 학습 플랫폼" 주제를 선택했나?

**A.** 회원·강의·카테고리·수강 관계가 **자연스럽게 1:N, N:M**을 만들고, 실무형 쿼리(인기 강의, 진도율, tier별 분석)를 SQL로 풀기 좋기 때문입니다.

---

### Q34. enrollment 테이블 역할은?

**A.** `member`와 `course` 사이의 **수강 신청 기록**을 저장하는 **중간(연결) 테이블**입니다.

- 누가(`member_id`) 어떤 강의(`course_id`)를
- 언제(`enrolled_at`) 수강했고
- 진도(`progress_pct`), 상태(`status`)가 어떤지

---

### Q35. (member_id, course_id) UNIQUE를 둔 이유?

**A.** **같은 회원이 같은 강의를 중복 수강 신청**하는 것을 방지합니다.

---

### Q36. tier 컬럼(FREE/PRO/ENTERPRISE)은 왜?

**A.** 회원 등급별 분석 쿼리를 위해 넣었습니다.  
예: PRO 회원 목록, tier별 수강 강의 가격 합계.

---

### Q37. progress_pct와 status를 같이 두는 이유?

**A.** 진도율(숫자)과 수강 **상태**(ACTIVE/COMPLETED/CANCELLED)는 다른 개념입니다.

- 진도 100%여도 status가 ACTIVE일 수 있음 → UPDATE로 COMPLETED 처리 (쿼리 #14)
- CANCELLED는 취소 → DELETE 대상 (쿼리 #15)

---

### Q38. 핵심 지표 3개(보너스)는?

**A.** `05_bonus_metrics.sql` 참고:

1. **카테고리별 수강 신청 건수** — 인기 카테고리
2. **강의별 수강 TOP 10 + 평균 진도율** — 베스트셀러 강의
3. **PRO 회원 평균 수강 진도율** — 유료 회원 참여도

---

## 11. 개발 환경 (Docker / MySQL)

### Q39. 왜 Docker로 MySQL을 띄웠나?

**A.**

- PC에 MySQL **직접 설치 없이** 동일 환경 재현
- 프로젝트별 DB 분리, `docker compose down -v`로 **초기화** 쉬움
- 팀원/강사와 **같은 버전(MySQL 8.4)** 공유 가능

---

### Q40. docker compose up / down 차이?

**A.**

```powershell
docker compose up -d      # MySQL 컨테이너 시작
docker compose down       # 컨테이너 중지 (데이터는 volume에 유지)
docker compose down -v    # 컨테이너 + volume 삭제 (DB 완전 초기화)
```

---

### Q41. 연결 정보는?

**A.**

| 항목 | 값 |
|------|-----|
| Host | `localhost` |
| Port | `3306` |
| Database | `codyssey` |
| User | `codyssey` |
| Password | `codyssey` |

---

### Q42. sql/init/ 폴더는 뭐하는 곳?

**A.** Docker MySQL **최초 기동 시** 자동 실행되는 SQL을 넣는 폴더입니다.  
이미 volume이 있으면 **다시 실행되지 않습니다.**  
수동 적용: `docker cp` + `mysql source` 또는 `capture_results.ps1` 전 schema/data 재실행.

---

### Q43. 한글이 깨질 때?

**A.**

- SQL 파일: **UTF-8** 저장
- MySQL 실행: `--default-character-set=utf8mb4`
- PowerShell에서 `docker exec` 출력 직접 저장 시 깨질 수 있음 → **컨테이너 내부 파일 → docker cp** 방식 사용 (`capture_results.ps1` 참고)
- DB 생성: `utf8mb4` / `utf8mb4_unicode_ci`

---

## 12. ORM / JPA 연결

### Q44. 이 과제와 JPA/ORM은 무슨 관련?

**A.** ORM이 내부적으로 하는 일(테이블 매핑, FK 관계, JOIN 조회)을 **SQL 관점에서 먼저 이해**하기 위한 과제입니다.

| SQL 개념 | JPA/ORM |
|----------|---------|
| PK | `@Id` |
| FK / 1:N | `@ManyToOne`, `@OneToMany` |
| JOIN | `@Query` JPQL, `fetch join` |
| UNIQUE | `@Column(unique=true)` |

---

### Q45. @OneToMany / @ManyToOne은 SQL로 보면?

**A.**

```java
// Course → Enrollment (1:N)
@OneToMany(mappedBy = "course")
List<Enrollment> enrollments;

// Enrollment → Course (N:1)
@ManyToOne
@JoinColumn(name = "course_id")
Course course;
```

SQL로는 `enrollment.course_id` FK 하나로 표현됩니다.

---

### Q46. N+1 문제란? (심화)

**A.** 1:N 조회 시 **부모 1번 + 자식 N번** 쿼리가 나가는 비효율입니다.  
SQL에서는 JOIN 한 번으로 해결:

```sql
SELECT m.nickname, c.title
FROM enrollment e
JOIN member m ON ...
JOIN course c ON ...
```

JPA에서는 `fetch join` 또는 `@EntityGraph`로 동일 목표를 달성합니다.

---

## 13. 보너스 과제 관련

### Q47. FK 에러를 일부러 내는 이유?

**A.** FK가 **실제로 동작**함을 증명하고, 에러 메시지를 읽고 **원인·해결**을 설명할 수 있게 하기 위함입니다.  
`results/bonus_fk_error.txt`에 ERROR 1452 기록.

---

### Q48. JOIN과 서브쿼리로 같은 결과를 내면?

**A.** **논리적으로 같은 집합**이면 OK. 실행 계획·성능은 DB와 데이터량에 따라 다를 수 있습니다.  
"결과 동일 + 코드 가독성 + 상황별 선택 기준"을 설명하면 좋습니다.

---

### Q49. 발표/리뷰에서 자주 나올 질문 TOP 5?

**A.**

1. **왜 테이블을 4개로 나눴는지** (중복·관계)
2. **FK가 없으면 어떤 문제가 생기는지**
3. **INNER JOIN과 LEFT JOIN 차이** (예시 포함)
4. **GROUP BY를 쓴 이유** (어떤 질문에 답하는지)
5. **인덱스를 그 컬럼에 건 이유**

---

### Q50. 과제를 마치면 할 수 있게 된 것?

**A.** (과제 목표 그대로 정리)

- [ ] DB가 엑셀과 뭐가 다른지 설명
- [ ] PK/FK, 1:N 관계를 말로 설명
- [ ] SELECT/INSERT/UPDATE/DELETE 구분
- [ ] JOIN, GROUP BY로 연결 데이터 조회 설명
- [ ] 검색/정렬/집계/랭킹 요구를 SQL로 풀기
- [ ] 인덱스 필요성과 적용 컬럼 선택 기준 이해

---

## 부록: 빠른 치트시트

```sql
-- 조회
SELECT ... FROM ... WHERE ... ORDER BY ... LIMIT ...;

-- 삽입 (부모 먼저!)
INSERT INTO table (col1, col2) VALUES (v1, v2);

-- 수정 (WHERE 필수!)
UPDATE table SET col = val WHERE id = 1;

-- 삭제 (WHERE 필수!)
DELETE FROM table WHERE status = 'CANCELLED';

-- INNER JOIN
FROM a INNER JOIN b ON a.id = b.a_id

-- LEFT JOIN
FROM a LEFT JOIN b ON a.id = b.a_id

-- 집계
SELECT col, COUNT(*), AVG(x), SUM(y)
FROM ...
GROUP BY col
HAVING COUNT(*) > 0;

-- 서브쿼리
WHERE id NOT IN (SELECT ... FROM ...)

-- 인덱스
CREATE INDEX idx_name ON table (column);
```

---

*마지막 업데이트: Codyssey_Database 프로젝트 기준*
