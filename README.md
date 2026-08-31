# Codyssey Database

코딩 학습 플랫폼 **Codyssey**를 주제로 한 MySQL 데이터베이스·SQL 과제입니다.  
백엔드 프레임워크나 ORM 없이 **순수 SQL**만으로 스키마, 샘플 데이터, 조회·변경 쿼리, 실행 결과를 제출합니다.

- DBMS: **MySQL 8.4** (Docker)
- 문자셋: `utf8mb4` / `utf8mb4_unicode_ci`
- 테이블 4개, 1:N 관계 3개 (`member` ↔ `course` 는 `enrollment`로 N:M)

---

## 목차

1. [과제 요구사항 대응](#과제-요구사항-대응)
2. [도메인과 ERD](#도메인과-erd)
3. [스키마와 제약조건](#스키마와-제약조건)
4. [샘플 데이터](#샘플-데이터)
5. [핵심 쿼리 16개](#핵심-쿼리-16개)
6. [보너스](#보너스)
7. [실행 방법](#실행-방법)
8. [결과 재생성](#결과-재생성)
9. [디렉터리 구조](#디렉터리-구조)
10. [연결 정보](#연결-정보)
11. [트러블슈팅](#트러블슈팅)
12. [참고 문서](#참고-문서)
13. [평가 문항 대비 (답변 포함)](#평가-문항-대비-답변-포함)
14. [예상 질문과 답변 (구술·복습)](#예상-질문과-답변-구술복습)

---

## 과제 요구사항 대응

| 요구 | 이 레포 |
|------|---------|
| 최소 4개 테이블 | `category`, `member`, `course`, `enrollment` |
| 1:N 관계 2개 이상 | category→course, member→enrollment, course→enrollment (3개) |
| 테이블당 샘플 10행 이상 | category 12, member 12, course 14, enrollment 18 |
| 기본 조회 (WHERE / ORDER BY / LIMIT) 4+ | 쿼리 #1–#4 |
| JOIN (INNER 2+, LEFT 1+) 4+ | 쿼리 #5–#9 (INNER 3, LEFT 2) |
| 집계 (COUNT / SUM / AVG + GROUP BY) 3+ | 쿼리 #10–#12 |
| 서브쿼리 1+ | 쿼리 #13 |
| UPDATE / DELETE 2+ | 쿼리 #14–#15 |
| INDEX 1+ | 쿼리 #16 (`enrollment.enrolled_at`) |
| 실행 결과 | `results/` |
| (선택) ERD | `erd.dbml` ([dbdiagram.io](https://dbdiagram.io) 붙여넣기) |

범위 밖: View, 프로시저, 트리거, Spring/Django 등 백엔드.

제출 핵심 파일:

| 파일 | 내용 |
|------|------|
| `sql/01_schema.sql` | CREATE DATABASE / TABLE, PK·FK·CHECK·UNIQUE |
| `sql/02_insert_sample_data.sql` | INSERT (FK 부모 → 자식 순서) |
| `sql/03_queries.sql` | 핵심 쿼리 모음 |
| `results/` | 쿼리·보너스 실행 결과 텍스트 |
| `erd.dbml` | ERD |

개별 쿼리는 `sql/queries/`에도 분리되어 있고, `03_queries.sql`과 내용이 같습니다.

---

## 도메인과 ERD

Codyssey는 회원(`member`)이 카테고리(`category`)에 속한 강의(`course`)를 수강(`enrollment`)하는 플랫폼입니다.

```
category (1) ──< (N) course (1) ──< (N) enrollment (N) >── (1) member
```

- **1:N**  
  - 한 카테고리에 여러 강의  
  - 한 회원이 여러 수강  
  - 한 강의에 여러 수강  
- **N:M**  
  - 회원 ↔ 강의는 `enrollment` 중간 테이블로 표현  
  - `(member_id, course_id)` UNIQUE → 동일 강의 중복 수강 신청 불가

`erd.dbml`을 [dbdiagram.io](https://dbdiagram.io)에 붙여 넣으면 ERD를 그릴 수 있습니다.

---

## 스키마와 제약조건

정의: `sql/01_schema.sql`

### category

| 컬럼 | 타입 | 제약 |
|------|------|------|
| id | INT AUTO_INCREMENT | PK |
| name | VARCHAR(50) | NOT NULL, UNIQUE |
| description | VARCHAR(255) | NULL |
| created_at | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

### member

| 컬럼 | 타입 | 제약 |
|------|------|------|
| id | INT AUTO_INCREMENT | PK |
| email | VARCHAR(100) | NOT NULL, UNIQUE |
| nickname | VARCHAR(50) | NOT NULL |
| tier | VARCHAR(20) | NOT NULL, DEFAULT `'FREE'`, CHECK `FREE` / `PRO` / `ENTERPRISE` |
| joined_at | DATE | NOT NULL |

### course

| 컬럼 | 타입 | 제약 |
|------|------|------|
| id | INT AUTO_INCREMENT | PK |
| category_id | INT | NOT NULL, FK → `category.id` (`ON DELETE RESTRICT`, `ON UPDATE CASCADE`) |
| title | VARCHAR(200) | NOT NULL |
| instructor | VARCHAR(100) | NOT NULL |
| price | DECIMAL(10,2) | NOT NULL, DEFAULT 0.00 |
| level | VARCHAR(20) | NOT NULL, CHECK `BEGINNER` / `INTERMEDIATE` / `ADVANCED` |
| published_at | DATE | NULL |

### enrollment

| 컬럼 | 타입 | 제약 |
|------|------|------|
| id | INT AUTO_INCREMENT | PK |
| member_id | INT | NOT NULL, FK → `member.id` |
| course_id | INT | NOT NULL, FK → `course.id` |
| enrolled_at | DATETIME | NOT NULL |
| progress_pct | TINYINT | NOT NULL, DEFAULT 0, CHECK 0–100 |
| status | VARCHAR(20) | NOT NULL, DEFAULT `'ACTIVE'`, CHECK `ACTIVE` / `COMPLETED` / `CANCELLED` |

복합 UNIQUE: `(member_id, course_id)`.

`progress_pct`(숫자 진도)와 `status`(수강 상태)는 별개입니다. 진도 100%여도 `ACTIVE`일 수 있고, 쿼리 #14가 이를 `COMPLETED`로 맞춥니다. `CANCELLED`는 쿼리 #15에서 삭제합니다.

FK는 자식 쪽에만 둡니다. 존재하지 않는 `member_id` / `course_id`로 INSERT하면 실패해야 정상입니다 (보너스 FK 테스트).

---

## 샘플 데이터

정의: `sql/02_insert_sample_data.sql`  
삽입 순서: **category → member → course → enrollment** (FK 부모 먼저).

| 테이블 | 행 수 | 비고 |
|--------|------|------|
| category | 12 | Backend, Frontend, DevOps, … |
| member | 12 | FREE / PRO / ENTERPRISE |
| course | 14 | 가격 0원(오픈소스) ~ 109,000원 |
| enrollment | 18 | ACTIVE / COMPLETED / CANCELLED, 진도 15–100% |

쿼리 #13용으로 **한 번도 수강하지 않은 회원**(`bae_guest`)이 포함되어 있습니다.

---

## 핵심 쿼리 16개

모음: `sql/03_queries.sql`  
분할: `sql/queries/01_basic_where.sql` … `16_create_index.sql`  
설명 목록: `sql/query_descriptions.txt`  
실행 결과: `results/query_01.txt` … `results/query_16_index.txt`

캡처 스크립트는 쿼리 #14·#15(UPDATE/DELETE)를 포함해 **앞에서부터 순서대로** 돌립니다. 지표 보너스는 UPDATE/DELETE **이전** 샘플 상태에서 먼저 캡처합니다.

### 기본 조회 (#1–#4)

| # | 내용 | 기법 |
|---|------|------|
| 1 | PRO 등급 회원 | `WHERE tier = 'PRO'` |
| 2 | 가격 5만 원 이상 강의, 가격 내림차순 | `WHERE` + `ORDER BY` |
| 3 | 최근 출간 강의 TOP 5 | `ORDER BY` + `LIMIT` |
| 4 | ACTIVE이면서 진도 50% 미만 | 복합 `WHERE` |

### JOIN (#5–#9)

| # | 내용 | 기법 |
|---|------|------|
| 5 | 수강 + 닉네임 + 강의 제목 | INNER JOIN (enrollment–member–course) |
| 6 | 강의 + 카테고리명 | INNER JOIN (course–category) |
| 7 | COMPLETED 수강 + 이메일 + 가격 | INNER JOIN + `WHERE` |
| 8 | 모든 회원 + 수강 건수 (0건 포함) | LEFT JOIN + `COUNT` |
| 9 | 모든 강의 + 수강 건수 (0건 포함) | LEFT JOIN + `COUNT` |

LEFT JOIN은 매칭이 없어도 부모 행을 남깁니다. 수강이 없는 회원·강의도 0건으로 나옵니다.

### 집계 (#10–#12)

| # | 내용 | 기법 |
|---|------|------|
| 10 | 강의별 수강 건수 TOP 10 | `COUNT` + `GROUP BY` |
| 11 | 카테고리별 평균 진도율 | `AVG` + `GROUP BY` |
| 12 | 회원 등급별 수강 강의 가격 합계 | `SUM` + `GROUP BY` |

### 서브쿼리·변경·인덱스 (#13–#16)

| # | 내용 | 기법 |
|---|------|------|
| 13 | 수강 신청이 한 번도 없는 회원 | `NOT IN` (또는 동등한 서브쿼리) |
| 14 | 진도 100% ACTIVE → COMPLETED | `UPDATE` |
| 15 | CANCELLED 수강 삭제 | `DELETE` |
| 16 | `enrolled_at` 인덱스 생성 후 확인 | `CREATE INDEX` + `SHOW INDEX` |

인덱스 `idx_enrollment_enrolled_at`는 기간별 수강 조회·정렬을 염두에 둔 것입니다. InnoDB는 FK 컬럼에 인덱스를 자동 생성하므로, 여기서는 FK가 아닌 `enrolled_at`에 명시적으로 걸었습니다.

---

## 보너스

필수 15개(+인덱스) 외에 아래를 넣었습니다.

### 1. FK 제약 위반 (`sql/04_bonus_fk_test.sql`)

존재하지 않는 `member_id = 9999`로 `enrollment` INSERT를 시도합니다.  
**ERROR 1452** (`Cannot add or update a child row: a foreign key constraint fails`)가 나와야 정상입니다.

결과: `results/bonus_fk_error.txt`

### 2. 핵심 지표 3개 (`sql/05_bonus_metrics.sql`)

| 지표 | 의미 |
|------|------|
| 카테고리별 수강 건수 | 인기 카테고리 |
| 강의별 수강 TOP 10 + 평균 진도 | 베스트셀러 |
| PRO 회원 평균 진도율 | 유료 회원 참여도 |

결과: `results/bonus_metrics.txt` 및 `results/bonus_metrics_01.txt` … `_03.txt`

### 3. JOIN vs 상관 서브쿼리 (`sql/bonus_join_subquery/`)

평균 이상 수강 건수를 가진 강의를 두 가지로 구합니다.

- 방식 1: `INNER JOIN` + `GROUP BY` + `HAVING`
- 방식 2: 상관 서브쿼리 + `HAVING`

결과: `results/bonus_join_vs_subquery.txt`

---

## 실행 방법

### 사전 요구

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (엔진이 떠 있어야 함)
- Windows에서는 PowerShell 기준

### 1. 환경 변수

```powershell
Copy-Item .env.example .env
```

`.env.example` 기본값:

```
MYSQL_PORT=3306
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=codyssey
MYSQL_USER=codyssey
MYSQL_PASSWORD=codyssey
```

`.env`는 git에 올리지 않습니다 (`.gitignore`).

### 2. MySQL 기동

```powershell
docker compose up -d
```

컨테이너 이름: `codyssey-mysql`. 헬스체크가 `healthy`가 될 때까지 수 초~수십 초 걸릴 수 있습니다.

`sql/init/`는 Docker **최초** 기동 시 `/docker-entrypoint-initdb.d`로 실행됩니다. 볼륨(`mysql_data`)이 이미 있으면 이 폴더는 다시 돌지 않습니다. 스키마·데이터는 아래처럼 수동으로 넣는 방식이 확실합니다.

### 3. 스키마·데이터 적용

```powershell
docker exec -i codyssey-mysql mysql -uroot -prootpassword --default-character-set=utf8mb4 < sql/01_schema.sql
docker exec -i codyssey-mysql mysql -uroot -prootpassword --default-character-set=utf8mb4 < sql/02_insert_sample_data.sql
```

`01_schema.sql`은 `DROP DATABASE IF EXISTS codyssey` 후 재생성합니다.

### 4. 쿼리 실행 예

```powershell
docker exec -i codyssey-mysql mysql -uroot -prootpassword --default-character-set=utf8mb4 -t codyssey < sql/03_queries.sql
```

또는 VS Code / Cursor SQLTools: `.vscode/settings.json`에 연결 `Codyssey`가 있습니다.

CLI 클라이언트 예 (클라이언트만 로컬에 있고 서버는 Docker인 경우):

```text
mysql -h 127.0.0.1 -P 3306 -u codyssey -pcodyssey codyssey
```

### 중지·초기화

```powershell
docker compose down          # 컨테이너 중지, 데이터 볼륨 유지
docker compose down -v       # 볼륨까지 삭제 → DB 완전 초기화
```

---

## 결과 재생성

`results/`는 사람이 다시 찍지 않고 스크립트로 맞춥니다.

전제: `codyssey-mysql` 컨테이너가 실행 중.

```powershell
powershell -ExecutionPolicy Bypass -File sql/capture_results.ps1
```

동작 요약:

1. `sql/`를 컨테이너 `/tmp/codyssey-sql`로 복사
2. 스키마·샘플 데이터를 처음부터 다시 적용
3. 보너스 지표를 **UPDATE/DELETE 전** 상태에서 캡처
4. `sql/queries/`를 번호순으로 실행해 `results/query_*.txt` 저장 (#16은 `query_16_index.txt`)
5. FK 위반 1건을 `results/bonus_fk_error.txt`로 저장
6. JOIN vs 서브쿼리 비교를 `results/bonus_join_vs_subquery.txt`로 저장

PowerShell에서 `docker exec` 표준출력을 바로 파일로 받으면 한글이 깨질 수 있어, **컨테이너 안 파일 → `docker cp`** 방식을 씁니다. SQL과 결과는 UTF-8입니다.

---

## 디렉터리 구조

```
.
├── docker-compose.yml      # MySQL 8.4
├── .env.example            # 연결·계정 템플릿
├── erd.dbml                # ERD (dbdiagram.io)
├── docs/
│   └── QA_예상질문답변.md  # 개념·과제·환경 Q&A
├── sql/
│   ├── 01_schema.sql
│   ├── 02_insert_sample_data.sql
│   ├── 03_queries.sql
│   ├── 04_bonus_fk_test.sql
│   ├── 05_bonus_metrics.sql
│   ├── capture_results.ps1
│   ├── queries/            # 쿼리 1개 = 파일 1개
│   ├── bonus_metrics/
│   ├── bonus_join_subquery/
│   └── init/               # Docker 최초 기동용 (현재 .gitkeep)
└── results/                # 실행 결과 텍스트
```

---

## 연결 정보

| 항목 | 값 |
|------|-----|
| Host | `127.0.0.1` / `localhost` |
| Port | `3306` (`MYSQL_PORT`) |
| Database | `codyssey` |
| User | `codyssey` |
| Password | `codyssey` |
| Root password | `rootpassword` (컨테이너 관리·스크립트용) |

과제용 로컬 비밀번호입니다. 외부에 같은 값을 쓰지 마세요.

---

## 트러블슈팅

### `ERROR 2003 ... Can't connect ... (10061)`

클라이언트가 아니라 **서버가 3306에서 안 떠 있는 상태**입니다.

1. Docker Desktop이 실행 중인지 확인 (`docker info`)
2. `docker compose up -d`
3. `docker inspect --format "{{.State.Health.Status}}" codyssey-mysql` 가 `healthy`인지 확인

이 PC에 MySQL을 따로 설치하지 않았다면, 연결 대상은 항상 이 Compose 컨테이너입니다.

### 스키마를 바꿨는데 데이터가 예전 그대로다

`sql/init/`는 볼륨이 있으면 재실행되지 않습니다. `01_schema.sql`을 다시 소스하거나 `docker compose down -v` 후 `up` 하세요.

### 한글 깨짐

- SQL 파일을 UTF-8로 저장
- mysql 실행 시 `--default-character-set=utf8mb4`
- 결과 캡처는 `capture_results.ps1` 사용

---

## 참고 문서

구술·복습용 Q&A는 아래 [예상 질문과 답변](#예상-질문과-답변-구술복습)에 정리해 두었고, 동일 내용의 원본은 `docs/QA_예상질문답변.md`에도 있습니다.

- PK / FK / 1:N / N:M, CHECK·UNIQUE
- JOIN·GROUP BY·서브쿼리·인덱스
- 제출 파일 목록과 범주별 쿼리 개수
- Docker Compose, 문자셋
- SQL 개념과 JPA 매핑의 대응 (과제는 SQL만 제출)

---

## 평가 문항 대비 (답변 포함)

아래는 과제 **평가문항 항목 1~5**를 이 레포(Codyssey) 기준으로 풀어 쓴 답입니다.
항목 1은 제출물 체크리스트, 항목 2~4는 구술 설명용, 항목 5는 보너스 크레딧입니다.

**DB를 처음 배운다는 전제**로, 각 답변은 다음 순서로 되어 있습니다.

1. **개념** — 용어가 무슨 뜻인지, 왜 필요한지
2. **이 프로젝트에서는** — Codyssey 스키마·쿼리에 어떻게 적용했는지
3. **한 줄 요약** — 발표에서 그대로 말할 수 있는 문장

---

### 항목 0 — 먼저 알아야 할 용어 30초 정리

이 아래 답변에 계속 나오는 단어들입니다. 여기만 이해하면 나머지는 다 읽힙니다.

| 용어 | 뜻 | Codyssey 예 |
|------|-----|-------------|
| **DB / DBMS** | 데이터를 담는 저장소 / 그 저장소를 관리하는 소프트웨어 | `codyssey` DB / MySQL 8.4 |
| **테이블(table)** | 한 가지 주제의 데이터를 담는 표 | `member`, `course` |
| **행(row, 레코드)** | 표의 한 줄 = 실제 사례 하나 | 회원 `kim_dev` 한 명 |
| **열(column, 컬럼)** | 표의 세로 칸 = 속성 | `email`, `price` |
| **스키마(schema)** | 테이블·컬럼·규칙의 설계도 | `sql/01_schema.sql` |
| **PK (기본키)** | 그 표에서 행 하나를 유일하게 가리키는 컬럼 | `member.id` |
| **FK (외래키)** | 다른 표의 PK를 가리키는 컬럼 | `enrollment.member_id` |
| **제약조건(constraint)** | DB가 강제로 지키는 규칙 | `NOT NULL`, `UNIQUE`, `CHECK` |
| **쿼리(query)** | DB에게 시키는 명령문 | `SELECT ... FROM member` |
| **인덱스(index)** | 빨리 찾기 위한 색인 | `idx_enrollment_enrolled_at` |
| **정규화** | 중복을 없애려고 표를 쪼개는 작업 | 카테고리명을 `category`로 분리 |

SQL 명령은 역할에 따라 이렇게 나뉩니다.

| 분류 | 하는 일 | 명령 |
|------|---------|------|
| **DDL** (정의) | 구조를 만들고 바꿈 | `CREATE`, `ALTER`, `DROP` |
| **DML** (조작) | 데이터를 넣고 고치고 지움 | `INSERT`, `UPDATE`, `DELETE` |
| **DQL** (조회) | 데이터를 읽음 | `SELECT` |

이 과제는 DDL(`01_schema.sql`) → DML(`02_insert_sample_data.sql`) → DQL·DML(`03_queries.sql`) 순서로 진행됩니다.

---

### 항목 1 — 제출물 체크 (구현 여부)

#### Q. 최소 4개 테이블이 존재하고, 각 테이블에 PK가 정의되어 있는가?

**개념 먼저.**
테이블은 "한 가지 주제의 표"입니다. 회원은 회원 표에, 강의는 강의 표에 담습니다.
그런데 표에 줄이 1만 개 쌓이면 "3번째 줄"처럼 위치로는 특정 행을 가리킬 수 없습니다. 순서는 언제든 바뀌기 때문입니다.
그래서 **행마다 절대 겹치지 않는 이름표**를 하나 붙이는데, 이게 **PK(Primary Key, 기본키)** 입니다.

PK의 3원칙:

1. **유일(UNIQUE)** — 같은 값이 두 행에 있으면 안 됨
2. **NOT NULL** — 비어 있으면 안 됨 (이름표 없는 행 = 가리킬 수 없는 행)
3. **불변** — 한 번 정해지면 바뀌지 않는 게 좋음

**왜 `id INT AUTO_INCREMENT`인가?**
이메일처럼 이미 유일한 값(= 자연키)을 PK로 써도 되긴 합니다. 하지만 회원이 이메일을 바꾸면, 그 회원을 가리키던 `enrollment` 행의 FK 값까지 전부 따라 바꿔야 합니다.
반면 `id`는 **아무 의미가 없는 번호(대리키, surrogate key)** 라서 절대 바뀔 일이 없습니다. `AUTO_INCREMENT`는 MySQL이 1, 2, 3… 을 자동으로 채워 주는 기능이라 번호 중복 걱정도 없습니다.

**이 프로젝트에서는.** `sql/01_schema.sql`에 4개 테이블이 있고, 모두 `id INT AUTO_INCREMENT`를 PRIMARY KEY로 둡니다.

| 테이블 | PK | 이 테이블이 담는 "한 줄"의 의미 |
|--------|-----|--------------------------------|
| `category` | `id` | 강의 분류 하나 (예: Backend) |
| `member` | `id` | 회원 한 명 |
| `course` | `id` | 강의 한 개 |
| `enrollment` | `id` | "누가 어떤 강의를 신청했다"는 사실 하나 |

```sql
CREATE TABLE member (
    id       INT          NOT NULL AUTO_INCREMENT,
    email    VARCHAR(100) NOT NULL,
    ...
    PRIMARY KEY (id),
    UNIQUE KEY uq_member_email (email)   -- 이메일은 PK는 아니지만 중복은 막음
) ENGINE=InnoDB;
```

이메일도 실제로는 유일해야 하므로 PK 대신 **UNIQUE 제약**으로 막았습니다.
(PK와 UNIQUE의 차이: PK는 테이블당 1개 + NULL 불가, UNIQUE는 여러 개 가능 + NULL 허용)

> **한 줄 요약** — 테이블 4개 모두 의미 없는 정수 `id`를 PK로 써서, 값이 바뀌어도 관계가 깨지지 않게 했습니다.

#### Q. FK를 사용한 1:N 관계가 최소 2개 이상 존재하고, 없는 값 참조가 실제로 막히는가?

**개념 먼저.**
**FK(Foreign Key, 외래키)** 는 "이 컬럼에는 저쪽 표에 실제로 있는 PK 값만 넣을 수 있다"는 규칙입니다.
이 규칙을 **참조 무결성(referential integrity)** 이라고 합니다.

왜 중요하냐면, 애플리케이션 코드에서만 검사하면 **검사를 깜빡한 코드 한 줄**이 곧바로 쓰레기 데이터를 만듭니다.
FK는 DB가 직접 막기 때문에, 어떤 경로로 INSERT가 들어와도(코드든, 콘솔이든, 배치든) 뚫리지 않습니다.

FK에는 "부모가 변하면 자식은 어떻게 할지" 옵션이 붙습니다.

| 옵션 | 뜻 | 이 프로젝트 선택 |
|------|-----|------------------|
| `ON DELETE RESTRICT` | 자식이 하나라도 있으면 부모 삭제 거부 | 채택 — 수강 기록이 있는 강의를 실수로 못 지우게 |
| `ON DELETE CASCADE` | 부모 지우면 자식도 같이 삭제 | 미채택 — 데이터가 조용히 사라지는 게 더 위험 |
| `ON UPDATE CASCADE` | 부모 PK가 바뀌면 자식 FK도 따라 바뀜 | 채택 — 안전장치 (실제로는 `id`가 안 바뀜) |

**이 프로젝트에서는.** 1:N 관계가 3개입니다.

| 부모 (1) | 자식 (N) | FK 컬럼 | 읽는 법 |
|----------|----------|---------|---------|
| `category` | `course` | `course.category_id` | 카테고리 1개에 강의 여러 개 |
| `member` | `enrollment` | `enrollment.member_id` | 회원 1명이 수강 여러 건 |
| `course` | `enrollment` | `enrollment.course_id` | 강의 1개에 수강 여러 건 |

없는 값 참조는 DB가 막습니다. `member_id = 9999`(존재하지 않는 회원)로 INSERT하면:

```text
ERROR 1452 ... FOREIGN KEY (`member_id`) REFERENCES `member` (`id`)
```

에러 번호도 알아 두면 좋습니다.

- **1452** — 자식을 INSERT/UPDATE했는데 부모가 없음 (지금 이 경우)
- **1451** — 자식이 남아 있는데 부모를 DELETE하려 함 (`ON DELETE RESTRICT` 때문)

증거: `results/bonus_fk_error.txt`, 재현용 SQL: `sql/04_bonus_fk_test.sql`.

> **한 줄 요약** — FK는 DB가 직접 지키는 규칙이라, 코드가 실수해도 존재하지 않는 회원의 수강 기록은 애초에 저장되지 않습니다.

#### Q. 각 테이블에 최소 10행 이상의 샘플 데이터가 입력되어 있는가?

**개념 먼저.**
샘플 데이터는 그냥 "숫자 채우기"가 아닙니다. 데이터가 2~3행뿐이면 JOIN 결과도 2~3줄, GROUP BY 결과도 1줄이라서 **쿼리가 맞는지 틀린지 구분이 안 됩니다.**
그리고 일부러 **경계 케이스(edge case)** 를 심어 둬야 LEFT JOIN이나 서브쿼리의 동작이 결과로 드러납니다.

**이 프로젝트에서는.** `sql/02_insert_sample_data.sql` 기준:

| 테이블 | 행 수 |
|--------|------|
| `category` | 12 |
| `member` | 12 |
| `course` | 14 |
| `enrollment` | 18 |

의도적으로 심어 둔 경계 케이스:

| 심어 둔 것 | 어느 쿼리에서 드러나는가 |
|------------|--------------------------|
| 수강 0건 회원 (`bae_guest`) | #8 LEFT JOIN에서 `enrollment_count = 0`, #13 서브쿼리 결과 |
| 수강 0건 강의 | #9 LEFT JOIN에서 인기 없는 강의로 표시 |
| `status = 'CANCELLED'` 행 | #15 DELETE 대상 |
| `progress_pct = 100`인데 `ACTIVE`인 행 | #14 UPDATE 대상 |
| `published_at`이 NULL인 강의 | #3에서 `IS NOT NULL`로 걸러짐 |

INSERT 순서도 중요합니다. FK 때문에 **부모부터** 넣어야 합니다: `category` → `member` → `course` → `enrollment`.
`enrollment`를 먼저 넣으면 참조할 회원·강의가 아직 없어서 1452로 실패합니다.

> **한 줄 요약** — 10행을 채우는 게 목적이 아니라, 0건 회원·취소 건 같은 예외 상황을 일부러 넣어서 쿼리가 제대로 동작하는지 눈으로 확인할 수 있게 했습니다.

#### Q. 기본 조회(4개), 조인(4개), 집계(3개), 서브쿼리(1개), 수정/삭제(2개), 인덱스(1개)를 포함한 쿼리 15개가 작성되어 있는가?

**A. 예.** 실제로는 **16개**(인덱스까지 포함). 모음: `sql/03_queries.sql`.

| 범주 | 요구 | 본 프로젝트 | 이 범주가 확인하는 능력 |
|------|------|-------------|--------------------------|
| 기본 조회 | 4 | #1–#4 | 필요한 행만 고르고(WHERE) 정렬·자르기(ORDER BY / LIMIT) |
| JOIN | 4 | #5–#9 (INNER 3 + LEFT 2) | 쪼개 놓은 테이블을 다시 붙여서 읽기 |
| 집계 | 3 | #10–#12 | 여러 행을 하나의 숫자로 요약하기 |
| 서브쿼리 | 1 | #13 | 쿼리 결과를 다른 쿼리의 입력으로 쓰기 |
| UPDATE / DELETE | 2 | #14 / #15 | 데이터를 안전하게 바꾸기 (WHERE 필수) |
| INDEX | 1 | #16 | 조회 성능을 의도적으로 개선하기 |

개별 파일은 `sql/queries/01_*.sql` … 로도 분리되어 있습니다.

#### Q. 각 쿼리의 실행 결과가 스크린샷 또는 텍스트로 첨부되어 있는가?

**A. 예.** `results/query_01.txt` … `results/query_16_index.txt` 텍스트로 첨부.
재생성: `powershell -File sql/capture_results.ps1`.

**왜 결과까지 내야 하는가.** SQL 파일만 있으면 그건 "쓴 것"이지 "돌아가는 것"이 아닙니다.
실행 결과가 있어야 문법 오류·논리 오류가 없다는 게 증명되고, 채점자가 DB를 직접 띄우지 않고도 확인할 수 있습니다.

---

### 항목 2 — 설계 설명 (구술)

#### Q. 테이블을 왜 이렇게 나눴는지, 각 테이블의 역할을 말할 수 있는가?

**개념 먼저 — 한 표에 다 넣으면 무슨 일이 생기나.**

만약 이 서비스를 표 하나(`수강기록`)로 만든다면 이렇게 됩니다.

| 회원이메일 | 닉네임 | 등급 | 카테고리 | 강의명 | 가격 | 진도 |
|---|---|---|---|---|---|---|
| kim@... | kim_dev | PRO | Backend | Spring Boot REST API | 79000 | 60 |
| kim@... | kim_dev | PRO | Backend | JPA와 Hibernate | 89000 | 20 |
| lee@... | lee_data | FREE | Backend | Spring Boot REST API | 79000 | 100 |

여기서 세 가지 문제가 생깁니다. 이걸 **이상 현상(anomaly)** 이라고 부릅니다.

1. **갱신 이상** — 카테고리명을 "Backend"에서 "백엔드"로 바꾸려면 관련된 모든 행을 UPDATE해야 합니다. 한 줄이라도 놓치면 같은 카테고리가 두 개로 갈라집니다.
2. **삽입 이상** — 아직 수강생이 한 명도 없는 신규 강의는 **등록할 방법이 없습니다.** 이 표는 "수강 사실"이 있어야만 행이 생기기 때문입니다.
3. **삭제 이상** — 마지막 수강 기록 한 줄을 지우면, 그 강의의 가격·강사 정보까지 **같이 사라집니다.**

이걸 막는 작업이 **정규화(normalization)** 이고, 원칙은 단순합니다.
**하나의 테이블은 하나의 주제(엔티티)만 담는다.**

주제를 찾는 방법은 요구사항에서 명사를 뽑아 보는 것입니다.
"**회원**이 **카테고리**에 속한 **강의**를 **수강**한다" → 명사 4개가 그대로 테이블 4개가 됩니다.

**이 프로젝트에서는.**

| 테이블 | 역할 | "한 줄 = 무엇" |
|--------|------|----------------|
| `category` | 강의 분류 (Backend, Frontend 등) | 분류 1개 |
| `member` | 플랫폼 회원 (이메일, 등급 tier) | 사람 1명 |
| `course` | 개별 강의 (가격, 난이도, 카테고리 소속) | 강의 1개 |
| `enrollment` | 누가·어떤 강의를·언제·어느 진도로 수강했는지 | 수강 사실 1건 |

앞의 세 가지 이상 현상이 실제로 어떻게 해결됐는지:

- 카테고리명 변경 → `category` 테이블 **한 줄만** UPDATE
- 수강생 없는 신규 강의 → `course`에 그냥 INSERT (수강 기록과 무관)
- 마지막 수강 취소 → `enrollment` 행만 삭제, `course` 정보는 그대로

> **한 줄 요약** — 회원·카테고리·강의·수강이라는 서로 다른 4개 주제를 한 표에 섞으면 수정·추가·삭제가 전부 꼬이기 때문에 주제별로 분리하고 FK로 다시 연결했습니다.

#### Q. FK로 연결한 1:N 관계가 실제 도메인에서 어떤 의미인지 예시를 들어 보여줄 수 있는가?

**개념 먼저 — 1:N인지 판단하는 방법.**
두 테이블 사이의 관계는 **양쪽에서 각각 물어보면** 결정됩니다.

- "카테고리 하나에 강의가 여러 개일 수 있나?" → **예**
- "강의 하나가 카테고리 여러 개에 속하나?" → **아니오** (하나만)

→ 한쪽만 "여러 개"이므로 **1:N**입니다. 양쪽 다 "여러 개"면 **N:M**입니다.

**FK는 항상 N(자식) 쪽에 둡니다.** 이유는 물리적입니다.
1쪽인 `category`에 강의 목록을 담으려면 한 칸에 `1,3,7,...` 처럼 여러 값을 넣어야 하는데, 관계형 DB의 칸에는 값이 하나만 들어갑니다.
반대로 N쪽인 `course`에 `category_id` 하나만 두면 자연스럽게 표현됩니다.

**이 프로젝트에서는.**

1. **category 1 : N course** — 「Backend」 카테고리 하나에 「Spring Boot REST API」「JPA와 Hibernate」 여러 강의가 속함.
   `course.category_id = category.id`
2. **member 1 : N enrollment** — `kim_dev` 한 명이 여러 강의를 수강함.
   `enrollment.member_id = member.id`
3. **course 1 : N enrollment** — 「SQL과 데이터 모델링 기초」 한 강의에 여러 회원이 신청함.
   `enrollment.course_id = course.id`

**N:M은 왜 중간 테이블로 푸나.**
회원과 강의는 "한 회원이 여러 강의를 듣고, 한 강의를 여러 회원이 듣는" 다대다입니다.
이걸 직접 표현할 방법이 없으므로, 사이에 `enrollment`를 두고 **1:N 두 개로 쪼갭니다.**

```text
member (1) ──< enrollment >── (1) course
```

중간 테이블의 이점은 하나 더 있습니다. **관계 자체의 속성**(언제 신청했는지 `enrolled_at`, 얼마나 들었는지 `progress_pct`, 상태 `status`)을 담을 자리가 생깁니다.
그리고 같은 사람이 같은 강의를 두 번 신청하지 못하게 `(member_id, course_id)`에 **복합 UNIQUE**를 걸었습니다.

```sql
UNIQUE KEY uq_enrollment_member_course (member_id, course_id)
```

> **한 줄 요약** — 회원↔강의는 다대다지만 관계형 DB는 다대다를 직접 못 담으므로, 수강이라는 중간 테이블로 1:N 두 개로 나누고 거기에 진도·상태 같은 관계 속성을 넣었습니다.

#### Q. 컬럼 타입(TEXT, INTEGER, DATE 등)을 왜 그렇게 선택했는지 설명할 수 있는가?

**개념 먼저.**
타입은 단순히 "저장 형식"이 아니라 **첫 번째 제약조건**입니다. 타입을 정하는 순간

- 들어올 수 있는 **값의 범위**가 정해지고 (`TINYINT`에 300은 못 들어감)
- 사용할 수 있는 **연산**이 정해지고 (`DATE`끼리는 뺄셈, 문자열은 안 됨)
- **정렬 방식**이 정해집니다 (문자열 `'10'`은 `'9'`보다 앞, 숫자 `10`은 `9`보다 뒤)

과제 예시에 나온 SQLite식 타입과 MySQL 타입은 이렇게 대응됩니다.

| 과제 표기 | MySQL에서 | 비고 |
|-----------|-----------|------|
| TEXT | `VARCHAR(n)` / `TEXT` | 길이를 아는 문자열은 `VARCHAR`가 원칙 |
| INTEGER | `INT`, `TINYINT`, `BIGINT` | 값 범위에 맞춰 크기 선택 |
| REAL | `DECIMAL`, `DOUBLE` | 돈은 반드시 `DECIMAL` |
| DATE / DATETIME | `DATE`, `DATETIME` | 시각이 필요하면 `DATETIME` |

**이 프로젝트에서는.**

| 컬럼 | 타입 | 이유 |
|------|------|------|
| `id` | `INT AUTO_INCREMENT` | 행 식별용 정수 PK. 4바이트로 약 21억까지 표현, 자동 증가로 충돌 방지 |
| `email`, `title` 등 | `VARCHAR(n)` | 실제 길이만큼만 저장하는 가변 문자열. `n`이 곧 최대 길이 제한이라 이상한 장문 입력을 막아 줌 |
| `price` | `DECIMAL(10,2)` | 금액. **부동소수(FLOAT/DOUBLE)는 0.1을 정확히 저장하지 못해** 합계에 오차가 누적됨. `(10,2)`는 전체 10자리 중 소수 2자리 |
| `progress_pct` | `TINYINT` | 0–100만 필요. 1바이트면 충분하고, `CHECK`로 범위까지 고정 |
| `joined_at`, `published_at` | `DATE` | 가입일·출간일은 "며칠"이면 충분, 시각은 불필요 |
| `enrolled_at`, `created_at` | `DATETIME` | 수강 시각·생성 시각은 시분초까지 있어야 순서 비교와 기간 집계가 가능 |
| `tier`, `level`, `status` | `VARCHAR` + `CHECK` | 허용 값 목록을 열거형처럼 고정 |

**타입만으로 부족한 부분은 제약조건으로 채웁니다.**

```sql
tier VARCHAR(20) NOT NULL DEFAULT 'FREE',
CONSTRAINT chk_member_tier CHECK (tier IN ('FREE', 'PRO', 'ENTERPRISE'))
```

`VARCHAR(20)`만 두면 `'프로'`, `'pro'`, `'PPRO'` 같은 오타가 다 들어옵니다. `CHECK`가 세 값 외에는 거부합니다.
(MySQL에는 `ENUM` 타입도 있지만, 값을 추가하려면 테이블 구조를 바꿔야 해서 표준 SQL인 `CHECK`를 썼습니다.)

이 스키마에 걸린 제약조건을 정리하면:

| 제약 | 하는 일 | 예 |
|------|---------|-----|
| `NOT NULL` | 빈 값 금지 | `email`, `title` |
| `UNIQUE` | 중복 금지 | `category.name`, `member.email` |
| `CHECK` | 값의 범위·목록 제한 | `progress_pct BETWEEN 0 AND 100` |
| `DEFAULT` | 안 넣으면 기본값 | `tier = 'FREE'`, `status = 'ACTIVE'` |
| `FOREIGN KEY` | 없는 부모 참조 금지 | `enrollment.member_id` |

> **한 줄 요약** — 타입은 첫 번째 제약조건이라 생각하고, 금액은 오차가 없는 DECIMAL, 0~100 값은 TINYINT+CHECK처럼 값의 성격에 맞춰 최소한의 범위만 허용하게 골랐습니다.

#### Q. 인덱스를 어떤 컬럼에 걸었고, 왜 그 컬럼이어야 하는지 이유를 대답할 수 있는가?

**개념 먼저 — 인덱스는 책 뒤의 색인입니다.**

500쪽짜리 책에서 "트랜잭션"이란 단어를 찾는 두 가지 방법이 있습니다.

- 1쪽부터 500쪽까지 전부 넘겨 보기 → DB에서는 **Full Table Scan**(전체 훑기)
- 책 뒤 색인에서 해당 항목을 찾아 페이지 번호로 바로 가기 → **인덱스 사용**

인덱스는 해당 컬럼 값을 **미리 정렬해 둔 별도의 자료구조(B+Tree)** 입니다. 정렬돼 있으니 이분 탐색이 가능해서, 100만 행에서도 몇 번의 비교로 위치를 찾습니다.

인덱스가 효과를 내는 상황:

- `WHERE 컬럼 = 값` (동등 비교)
- `WHERE 컬럼 BETWEEN a AND b`, `>`, `<` (**범위 검색** — 정렬돼 있어서 특히 강함)
- `ORDER BY 컬럼` (이미 정렬돼 있으니 다시 정렬할 필요가 없음)

인덱스의 비용도 반드시 같이 말해야 합니다:

- INSERT/UPDATE/DELETE 때마다 **인덱스도 같이 갱신**해야 해서 쓰기가 느려짐
- 별도의 디스크 공간 차지
- 그래서 "모든 컬럼에 인덱스"는 최악의 선택

**이 프로젝트에서는.** `enrollment.enrolled_at`에 `idx_enrollment_enrolled_at`를 걸었습니다. (`sql/queries/16_create_index.sql`)

```sql
CREATE INDEX idx_enrollment_enrolled_at ON enrollment (enrolled_at);
```

선택 이유:

1. **가장 자주 쓰일 조건이라서** — 「최근 30일 수강 건수」「월별 수강 추이」처럼 `enrolled_at` 범위로 자르는 조회가 학습 플랫폼의 핵심 지표입니다.
2. **카디널리티(값의 다양성)가 높아서** — 수강 시각은 거의 모든 행이 다른 값이라, 인덱스로 후보를 크게 좁힐 수 있습니다. 반대로 `status`는 값이 3개뿐이라 인덱스를 걸어도 전체의 1/3밖에 못 줄여서 효과가 적습니다.
3. **범위 검색과 정렬에 동시에 쓰여서** — `WHERE enrolled_at >= ... ORDER BY enrolled_at`는 인덱스 하나로 필터와 정렬을 둘 다 해결합니다.

일부러 **안 건** 것도 설명 포인트입니다.

- `member_id`, `course_id`는 FK인데, **InnoDB는 FK를 만들 때 인덱스를 자동으로 생성**합니다. 중복해서 걸 필요가 없습니다.
- `enrollment`의 `(member_id, course_id)` UNIQUE 제약도 내부적으로 인덱스입니다.
- `tier`, `status`, `level`은 카디널리티가 낮아 제외했습니다.

확인 방법:

```sql
SHOW INDEX FROM enrollment WHERE Key_name = 'idx_enrollment_enrolled_at';
EXPLAIN SELECT * FROM enrollment WHERE enrolled_at >= '2025-01-01';
```

`EXPLAIN`의 `key` 칼럼에 인덱스 이름이 뜨면 사용된 것입니다.
다만 **샘플이 18행뿐이라 옵티마이저가 "그냥 다 읽는 게 빠르다"고 판단해 인덱스를 안 쓸 수 있습니다.** 이건 인덱스가 잘못된 게 아니라 데이터가 작아서이며, 행이 수만 건으로 늘면 인덱스 쪽이 선택됩니다. 이 점을 함께 말하면 이해도가 드러납니다.

> **한 줄 요약** — 기간 조회가 잦고 값이 다양한 `enrolled_at`에만 인덱스를 걸었고, FK 컬럼은 InnoDB가 자동으로 인덱스를 만들기 때문에 중복해서 걸지 않았습니다.

---

### 항목 3 — 개념 + 본인 스키마로 설명

#### Q. 데이터베이스가 엑셀과 무엇이 다른지, 왜 테이블을 나눠 저장하는지 비교하며 설명할 수 있는가?

**개념 먼저.**
엑셀도 행과 열이 있는 표라서 겉모습은 DB와 비슷합니다. 진짜 차이는 **규칙이 어디에 있느냐**입니다.

엑셀에서 규칙은 **사람 머릿속**에 있습니다. "여기엔 숫자만 넣기로 했지"는 지키는 사람이 지킬 때만 유지됩니다.
DB에서 규칙은 **데이터 옆에 저장**됩니다. `CHECK (progress_pct BETWEEN 0 AND 100)`은 누가 어떤 방법으로 접근하든 예외 없이 적용됩니다.

| | 엑셀 | DB (본 과제) |
|---|------|----------------|
| 관계 | 사람이 시트·셀을 눈으로 맞춤 | FK로 **없는 부모 참조를 DB가 거부** |
| 중복 | 복사·붙여넣기로 반복되기 쉬움 | 정규화 + UNIQUE로 **한 곳만 수정** |
| 값 검증 | 서식·수식으로 권고 수준 | `NOT NULL`, `CHECK`로 **강제** |
| 동시 접근 | 파일을 나눠 쓰면 마지막 저장이 이김 | 트랜잭션·잠금으로 **동시에 안전하게** |
| 대용량 | 수십만 행부터 급격히 느려짐 | 인덱스로 **필요한 부분만 읽음** |
| 조회 | 필터·피벗을 매번 손으로 | SQL로 JOIN·집계를 **재현 가능하게** |

**트랜잭션**을 한 줄로 설명하면: "여러 작업을 묶어서 **전부 성공하거나 전부 취소**되게 하는 단위"입니다.
예를 들어 수강 신청과 결제 기록이 함께 저장돼야 하는데 중간에 실패하면, 엑셀은 반쯤 저장된 상태로 남지만 DB는 통째로 되돌립니다.

**테이블을 나눈 이유를 이 스키마로.**
`course`마다 카테고리명을 문자열로 직접 넣었다고 해 봅시다.

```text
course: (1, 'Backend',  'Spring Boot REST API')
        (2, 'backend',  'JPA와 Hibernate')       ← 소문자 오타
        (3, 'Back-End', 'Node.js 입문')          ← 표기 불일치
```

이러면 "Backend 카테고리 강의 개수"를 세는 순간 답이 틀립니다. 이름을 바꾸려면 모든 행을 고쳐야 하고, 하나 놓치면 카테고리가 갈라집니다.
`category` 테이블로 분리하고 `course.category_id`로 가리키면:

- 이름은 `category` 한 줄만 고치면 전부 반영됨
- `UNIQUE KEY uq_category_name (name)` 덕분에 애초에 같은 이름이 두 번 등록되지 않음
- FK 덕분에 존재하지 않는 카테고리를 가리키는 강의가 생길 수 없음

> **한 줄 요약** — 엑셀은 규칙이 사람 머릿속에 있고 DB는 규칙이 데이터 옆에 저장돼 있어서, DB에서는 잘못된 데이터가 애초에 저장되지 않습니다.

#### Q. PK와 FK의 역할을 구분하고, 1:N 관계가 데이터를 어떻게 연결하는지 본인 스키마 기준으로 보여줄 수 있는가?

**개념 먼저.**
둘 다 "키"라는 이름이 붙어 헷갈리지만, 방향이 반대입니다.

- **PK는 안쪽을 향합니다.** "이 표 안에서 이 행이 누구인지" 알려 주는 이름표.
- **FK는 바깥을 향합니다.** "다른 표의 누구를 가리키는지" 알려 주는 화살표.

| | PK | FK |
|---|-----|-----|
| 목적 | 행을 유일하게 식별 | 다른 테이블의 행을 참조 |
| 위치 | 모든 테이블에 1개 | 관계의 **N(자식)** 쪽에 |
| 중복 | 불가 | **가능** (한 회원이 수강 여러 건) |
| NULL | 불가 | 가능 (관계가 선택적이면) — 이 프로젝트는 전부 `NOT NULL` |
| 개수 | 테이블당 1개 | 여러 개 가능 (`enrollment`는 2개) |

**이 프로젝트에서는.**

- **PK**: `member.id = 1` → 회원 `kim_dev` 딱 한 명.
- **FK**: `enrollment.member_id = 1` → 이 수강 행은 `kim_dev`의 것.
  같은 값 `1`이 여러 수강 행에 반복될 수 있고, 그게 바로 "1명이 여러 건"이라는 **1:N**의 실제 모습입니다.

실제 데이터로 따라가면:

```text
member.id = 1 (kim_dev)
    ├─ enrollment (id=1, member_id=1, course_id=1, progress=60)
    └─ enrollment (id=2, member_id=1, course_id=2, progress=20)   ← 같은 member_id 반복 = 1:N
                                     │
                                     └─ course.id = 2 (JPA와 Hibernate)
                                             └─ category.id = 1 (Backend)
```

이 화살표를 따라가는 SQL이 곧 JOIN입니다.

```sql
SELECT m.nickname, c.title, cat.name
FROM enrollment e
INNER JOIN member   m   ON e.member_id   = m.id     -- FK = PK
INNER JOIN course   c   ON e.course_id   = c.id     -- FK = PK
INNER JOIN category cat ON c.category_id = cat.id;  -- FK = PK
```

**JOIN 조건 `ON`은 결국 "FK 값 = 부모 PK 값"** 입니다. 스키마를 잘 나눠 두면 JOIN 조건은 저절로 정해집니다.

> **한 줄 요약** — PK는 자기 표 안에서 행을 가리키는 이름표, FK는 다른 표의 이름표를 가리키는 화살표이고, 그 화살표를 따라가는 게 JOIN입니다.

#### Q. INNER JOIN과 LEFT JOIN의 차이를 실행 결과를 보며 짚어줄 수 있는가?

**개념 먼저.**
JOIN은 **쪼개 놓은 두 표를 조건에 맞춰 한 줄로 붙이는 연산**입니다. `ON` 뒤가 붙이는 조건입니다.

```text
INNER JOIN                 LEFT JOIN
  member  enrollment         member  enrollment
 ┌──────┬──────┐            ┌──────┬──────┐
 │      │██████│            │██████│██████│   ← 왼쪽(member)은 전부 남고,
 └──────┴──────┘            └──────┴──────┘     짝이 없으면 오른쪽 컬럼은 NULL
  양쪽 다 짝이 있는 행만      왼쪽 전부 + 짝이 있으면 붙임
```

- **INNER JOIN** — 양쪽에 **모두 짝이 있는 행만** 남습니다. 짝 없는 행은 조용히 사라집니다.
- **LEFT JOIN** — **왼쪽(기준) 테이블은 전부** 남기고, 오른쪽에 짝이 없으면 오른쪽 컬럼을 전부 `NULL`로 채웁니다.

**언제 무엇을 쓰나.**
"~한 것들"을 볼 땐 INNER, "**~하지 않은 것도 포함해서 전부**"를 볼 땐 LEFT입니다.
"수강 0건인 회원을 찾아라", "아무도 안 듣는 강의를 찾아라" 같은 요구는 INNER로는 절대 못 풉니다. 그 행들은 애초에 결과에서 빠지기 때문입니다.

**이 프로젝트에서는.**

- **#5–#7 INNER JOIN** — 수강 기록이 실제로 있는 건만. `bae_guest`(수강 0건)는 결과에 아예 없습니다.
- **#8–#9 LEFT JOIN** — 회원 12명 전원, 강의 14개 전부가 나오고, 짝이 없으면 `enrollment_count = 0`.

```sql
-- #8: 모든 회원 + 수강 건수 (0건 포함)
SELECT m.id, m.nickname, m.tier, COUNT(e.id) AS enrollment_count
FROM member m
LEFT JOIN enrollment e ON m.id = e.member_id
GROUP BY m.id, m.nickname, m.tier
ORDER BY enrollment_count ASC, m.nickname;
```

결과 파일 `results/query_05.txt`(INNER) vs `results/query_08.txt`(LEFT)를 나란히 놓으면 **행 수 자체가 다릅니다.**

**여기서 자주 틀리는 두 가지 — 이걸 말하면 확실히 이해한 걸로 보입니다.**

1. **`COUNT(*)` vs `COUNT(e.id)`**
   `COUNT(*)`는 **행 개수**를 셉니다. LEFT JOIN에서 짝이 없어도 NULL로 채운 행 하나는 존재하므로 **0이 아니라 1**이 나옵니다.
   `COUNT(e.id)`는 **NULL이 아닌 값의 개수**를 셉니다. 짝이 없으면 `e.id`가 NULL이므로 정확히 **0**이 나옵니다.
   → LEFT JOIN에서 "0건"을 세려면 반드시 오른쪽 테이블의 컬럼을 지정해야 합니다.

2. **LEFT JOIN인데 WHERE에 오른쪽 조건을 걸면 INNER가 됨**
   ```sql
   FROM member m LEFT JOIN enrollment e ON m.id = e.member_id
   WHERE e.status = 'ACTIVE'     -- NULL은 이 조건을 통과 못 해 0건 회원이 사라짐
   ```
   조건을 유지하면서 0건도 남기려면 `ON` 절로 옮겨야 합니다.
   ```sql
   LEFT JOIN enrollment e ON m.id = e.member_id AND e.status = 'ACTIVE'   -- 이렇게
   ```
   이유는 실행 순서 때문입니다. `ON`은 **붙일 때** 적용되고, `WHERE`는 **다 붙인 뒤** 걸러내기 때문입니다.

> **한 줄 요약** — INNER는 양쪽에 짝이 있는 행만, LEFT는 왼쪽을 전부 남기므로 "수강 0건 회원"처럼 없는 것을 찾는 질문은 LEFT JOIN + `COUNT(자식컬럼)`으로 풀어야 합니다.

#### Q. GROUP BY와 집계 함수(COUNT, SUM, AVG)가 어떻게 동작하는지 쿼리 결과를 이야기할 수 있는가?

**개념 먼저.**
`GROUP BY`는 **같은 값을 가진 행들을 한 덩어리로 접고, 덩어리마다 대표값 하나를 계산**하는 연산입니다.

```text
enrollment 원본                GROUP BY course_id 후
course_id | progress           course_id | COUNT(*) | AVG(progress)
    1     |   60                   1     |    3     |     70
    1     |   80        ──▶        2     |    2     |     40
    1     |   70
    2     |   20
    2     |   60
```

핵심은 **결과의 행 수가 "그룹의 개수"로 줄어든다**는 점입니다. 그래서 `GROUP BY`를 쓴 뒤에는 개별 행의 값을 그냥 꺼낼 수 없고, 집계 함수를 통해야만 합니다.

주요 집계 함수:

| 함수 | 하는 일 | NULL 처리 |
|------|---------|-----------|
| `COUNT(*)` | 행 개수 | NULL 포함해서 셈 |
| `COUNT(컬럼)` | 그 컬럼이 NULL이 **아닌** 행 개수 | NULL 제외 |
| `COUNT(DISTINCT 컬럼)` | 중복 제거한 값의 개수 | NULL 제외 |
| `SUM(컬럼)` | 합계 | NULL 무시 |
| `AVG(컬럼)` | 평균 | NULL 무시 (**분모에서도 빠짐**) |
| `MAX` / `MIN` | 최대 / 최소 | NULL 무시 |

**SQL의 실행 순서를 알면 전부 설명됩니다.**
SQL은 쓰는 순서와 **실행되는 순서가 다릅니다.**

```text
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
  ①      ②      ③        ④         ⑤        ⑥        ⑦        ⑧
```

여기서 두 가지가 따라 나옵니다.

- **`WHERE`와 `HAVING`의 차이** — `WHERE`는 그룹으로 묶기 **전에 개별 행**을 거르고, `HAVING`은 묶은 **후에 그룹**을 거릅니다.
  "취소 건은 빼고(WHERE) 집계한 뒤, 수강 5건 이상인 강의만(HAVING) 보기"처럼 둘 다 쓸 수 있습니다.
- **`SELECT`의 별칭(alias)을 `WHERE`에서 못 쓰는 이유** — `SELECT`가 `WHERE`보다 나중에 실행되기 때문입니다. 반대로 `ORDER BY`는 `SELECT` 다음이라 별칭을 쓸 수 있습니다.

**`ONLY_FULL_GROUP_BY`.** MySQL 8은 기본으로 이 모드가 켜져 있어서, `SELECT`에 올린 **집계가 아닌 컬럼은 전부 `GROUP BY`에 있어야** 합니다.
`GROUP BY c.id, c.title`처럼 제목까지 넣은 이유가 이것입니다. (`c.id`가 PK라서 `c.title`은 논리적으로 하나로 정해지지만, 명시해 두는 편이 안전하고 이식성도 좋습니다.)

**이 프로젝트에서는.**

| 쿼리 | 묶는 단위 | 집계 | 의미 |
|------|-----------|------|------|
| #10 | 강의 | `COUNT(e.id)` | 강의별 수강 신청 건수 TOP 10 |
| #11 | 카테고리 | `AVG(progress_pct)` | 카테고리별 평균 진도율 |
| #12 | 회원 tier | `SUM(price)` | 등급별 「수강 중인 강의 가격」 합 |

읽는 법 예시(#10): 같은 `course_id`를 가진 `enrollment` 행 여러 개가 한 그룹이 되고, 그 그룹의 행 수가 `total_enrollments`입니다.
#10은 LEFT JOIN을 써서 **수강 0건 강의도 0으로** 나오고, #11은 INNER JOIN + `HAVING enrollment_count > 0`으로 **수강이 있는 카테고리만** 남깁니다. 목적에 따라 JOIN 종류를 바꿨다는 점이 설명 포인트입니다.

> **한 줄 요약** — GROUP BY는 같은 값의 행들을 접어서 그룹당 한 줄로 만드는 연산이고, WHERE는 접기 전 행을, HAVING은 접은 후 그룹을 거릅니다.

---

### 항목 4 — 과정 회고 (구술)

#### Q. 작성한 쿼리 중 가장 복잡했던 쿼리를 선택하고, 어떻게 풀었는지 단계별로 설명할 수 있는가?

**개념 먼저 — 서브쿼리란.**
서브쿼리는 **쿼리 안에 들어간 또 다른 쿼리**입니다. "먼저 이걸 계산하고, 그 결과를 조건으로 쓰자"를 SQL 한 문장으로 표현하는 방법입니다.

위치와 형태에 따라 이름이 다릅니다.

| 종류 | 반환 | 쓰는 자리 | 예 |
|------|------|-----------|-----|
| 스칼라 서브쿼리 | 값 1개 | `SELECT`, `WHERE` 우변 | `(SELECT AVG(...) ...)` |
| 다중 행 서브쿼리 | 값 여러 개 | `IN`, `NOT IN`, `EXISTS` | `WHERE id NOT IN (...)` |
| 파생 테이블 | 표 | `FROM` | `FROM (SELECT ...) AS sub` |
| 상관 서브쿼리 | 바깥 행마다 재계산 | 어디든 | `WHERE e.course_id = c.id` |

**상관(correlated) 서브쿼리**만 조금 다릅니다. 안쪽 쿼리가 **바깥 쿼리의 컬럼을 참조**하기 때문에, 바깥 행이 바뀔 때마다 안쪽이 다시 실행됩니다. 이해하긴 쉽지만 행 수가 많아지면 느려질 수 있습니다.

---

**선택 1: #13 「한 번도 수강하지 않은 회원」**

```sql
SELECT id, email, nickname, joined_at
FROM member
WHERE id NOT IN (
    SELECT DISTINCT member_id
    FROM enrollment
)
ORDER BY joined_at;
```

단계별로:

1. **목표 정의** — `enrollment`에 단 한 줄도 없는 `member`를 찾는다. "없는 것을 찾는" 문제라 단순 INNER JOIN으로는 안 됩니다.
2. **안쪽부터 푼다** — `SELECT DISTINCT member_id FROM enrollment` → 수강한 적이 있는 회원 ID의 **집합**을 만듭니다.
3. **바깥에서 뒤집는다** — `member`에서 `id NOT IN (그 집합)` → 그 집합에 없는 회원만 남습니다.
4. **검증** — 샘플에 일부러 심어 둔 `bae_guest`가 나오는지 확인 (`results/query_13.txt`). 심어 둔 값이 나와야 쿼리가 맞다는 증거가 됩니다.

**여기서 반드시 알아야 할 함정 — `NOT IN`과 NULL.**
서브쿼리 결과에 `NULL`이 하나라도 섞이면, `NOT IN`은 **결과가 통째로 0행**이 됩니다.
SQL에서 `NULL`은 "값이 없음"이 아니라 "**모름**"이라서, `id != NULL`의 결과가 참도 거짓도 아닌 `UNKNOWN`이 되고 조건을 통과하지 못하기 때문입니다.

이 프로젝트는 `enrollment.member_id`가 `NOT NULL`이라 안전하지만, 안전한 대안 두 가지도 알아 두면 좋습니다.

```sql
-- 대안 1: NOT EXISTS (NULL에 안전, 보통 성능도 좋음)
SELECT m.id, m.email, m.nickname
FROM member m
WHERE NOT EXISTS (SELECT 1 FROM enrollment e WHERE e.member_id = m.id);

-- 대안 2: LEFT JOIN + IS NULL (앞의 LEFT JOIN 개념 그대로 활용)
SELECT m.id, m.email, m.nickname
FROM member m
LEFT JOIN enrollment e ON m.id = e.member_id
WHERE e.id IS NULL;
```

같은 질문을 세 가지 방법으로 풀 수 있고 그중 왜 이걸 골랐는지 말하면, 쿼리를 외운 게 아니라 이해한 것으로 보입니다.

---

**선택 2 (보너스): 「평균 이상 수강 건수 강의」**

```sql
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
```

단계별로:

1. **강의별 건수를 센다** — `GROUP BY course_id` → 강의마다 한 줄, 값은 수강 건수
2. **"평균 건수"를 구한다** — 여기가 어려운 부분입니다. `AVG(COUNT(*))`처럼 집계 함수를 겹쳐 쓸 수 없으므로, ①의 결과를 **파생 테이블**(`FROM (...) AS sub`)로 만든 뒤 그 위에 `AVG`를 한 번 더 겁니다. 이게 **2단 집계**입니다.
3. **필터** — `HAVING COUNT(e.id) >= (그 평균)`. 그룹을 거르는 조건이므로 `WHERE`가 아니라 `HAVING`입니다.
4. **비교** — 같은 요구를 상관 서브쿼리 방식으로도 작성해 두 방식의 결과가 일치함을 확인했습니다 (`results/bonus_join_vs_subquery.txt`).

두 방식의 차이를 한 줄로:
**JOIN + GROUP BY**는 한 번에 묶어서 세고, **상관 서브쿼리**는 강의 한 줄마다 `COUNT`를 다시 실행합니다. 결과는 같지만 앞쪽이 보통 더 효율적입니다.

> **한 줄 요약** — 가장 어려웠던 건 「평균 이상」처럼 집계 결과를 다시 집계해야 하는 쿼리였고, 파생 테이블로 한 단계 내려서 계산한 뒤 HAVING으로 거르는 방식으로 풀었습니다.

#### Q. 미션 수행 중 가장 어려웠던 부분과 해결 방법을 구체적으로 말할 수 있는가?

**A. (예시 답안 — 발표 시 본인 경험에 맞게 바꿔도 됨)**

각 항목을 **증상 → 원인 → 해결 → 배운 것** 순으로 정리했습니다.

**1. FK 때문에 INSERT가 계속 실패**

- 증상: `enrollment` INSERT에서 `ERROR 1452`
- 원인: 참조할 `member`·`course` 행이 아직 없는 상태에서 자식부터 넣었음
- 해결: `category` → `member` → `course` → `enrollment` 순으로 **부모부터** INSERT
- 배운 것: FK는 삽입 순서까지 강제한다. 반대로 **삭제는 자식부터**여야 한다는 것도 같은 이유

**2. LEFT JOIN을 썼는데 0건 회원이 안 보임**

- 증상: `COUNT(*)`로 세니 수강 0건인 `bae_guest`가 `1`로 나옴
- 원인: LEFT JOIN은 짝이 없어도 NULL로 채운 행을 하나 만들고, `COUNT(*)`는 그 행도 세기 때문
- 해결: `COUNT(e.id)`로 변경 → NULL은 세지 않으므로 정확히 `0`
- 배운 것: 집계 함수의 **NULL 처리 규칙**이 결과를 바꾼다

**3. 결과 파일의 한글이 깨짐**

- 증상: `results/*.txt`에 한글이 `?`나 깨진 문자로 저장됨
- 원인: PowerShell에서 `docker exec` 출력을 바로 리다이렉트하면 콘솔 인코딩(CP949)을 거치며 UTF-8이 손상됨
- 해결: 컨테이너 **안에서** 파일로 쓴 뒤 `docker cp`로 꺼내오도록 `sql/capture_results.ps1`을 통일
- 배운 것: DB만 `utf8mb4`면 되는 게 아니라 **클라이언트·터미널·파일까지 인코딩이 이어져야** 한다

**4. UPDATE/DELETE 때문에 결과가 달라짐**

- 증상: 보너스 지표를 다시 뽑으니 앞서 캡처한 값과 숫자가 안 맞음
- 원인: #14(UPDATE)와 #15(DELETE)가 실제로 데이터를 바꾸는데, 그 뒤에 집계를 돌렸음
- 해결: 캡처 스크립트를 **① 원본 상태에서 지표·조회 → ② UPDATE/DELETE → ③ 변경 결과** 순서로 고정
- 배운 것: SELECT는 몇 번을 돌려도 같지만 UPDATE/DELETE는 **한 번 실행하면 상태가 바뀐다.** 그래서 실행 전에 같은 `WHERE`로 `SELECT`를 먼저 돌려 대상 행을 확인하는 습관이 필요하다

```sql
-- UPDATE 전에 반드시: 같은 WHERE로 대상을 먼저 확인
SELECT * FROM enrollment WHERE progress_pct = 100 AND status = 'ACTIVE';
UPDATE enrollment SET status = 'COMPLETED' WHERE progress_pct = 100 AND status = 'ACTIVE';
```

> **한 줄 요약** — FK가 INSERT 순서를, NULL 규칙이 COUNT 결과를, 인코딩이 파일 출력을 각각 좌우한다는 걸 실패하면서 배웠고, 마지막엔 UPDATE/DELETE가 상태를 바꾸므로 캡처 순서를 고정해야 한다는 걸 알았습니다.

---

### 항목 5 — 보너스 크레딧

평가표: **보너스 문제 해결에 따른 크레딧 부여(100)**

본 레포에서 준비한 보너스:

| 보너스 | 파일 | 결과 |
|--------|------|------|
| FK 위반으로 제약 동작 증명 | `sql/04_bonus_fk_test.sql` | `results/bonus_fk_error.txt` (ERROR 1452) |
| 핵심 지표 3개 미니 리포트 | `sql/05_bonus_metrics.sql` | `results/bonus_metrics.txt` |
| JOIN vs 상관 서브쿼리 동일 문제 | `sql/bonus_join_subquery/` | `results/bonus_join_vs_subquery.txt` |

발표 시: 「없는 회원 ID로 INSERT → 1452로 막힘」「카테고리·강의·PRO 진도 지표」「같은 조건을 JOIN/서브쿼리 두 방식으로」를 짧게 보여 주면 됩니다.

---

## 예상 질문과 답변 (구술·복습)

`docs/QA_예상질문답변.md`를 정리한 버전입니다.  
프로젝트: Codyssey / MySQL 8.4 / 테이블 `category`, `member`, `course`, `enrollment`.

| 구역 | 내용 |
|------|------|
| Q1–Q4 | DB 기본 개념 |
| Q5–Q9 | 모델링·관계 |
| Q10–Q13 | 제약·무결성 |
| Q14–Q16 | CRUD |
| Q17–Q19 | JOIN |
| Q20–Q22 | 집계·GROUP BY |
| Q23–Q24 | 서브쿼리 |
| Q25–Q27 | 인덱스 |
| Q28–Q32 | 제출물 |
| Q33–Q38 | Codyssey 설계 |
| Q39–Q43 | Docker / MySQL |
| Q44–Q46 | ORM / JPA 연결 |
| Q47–Q50 | 보너스·발표 |

---

### 1. 데이터베이스 기본 개념

#### Q1. 엑셀과 DB의 차이는 뭔가요?

**A.** 차이는 데이터 양이 아니라 **구조와 규칙**입니다.

| | 엑셀 | DB |
|---|------|-----|
| 관계 | 사람이 시트·열로 맞춤 | FK로 관계를 **강제** |
| 중복 | 수동 관리 | UNIQUE, PK 등으로 방지 |
| 동시 접근 | 충돌 위험 | 트랜잭션으로 안전하게 처리 |
| 대용량 | 느려지기 쉬움 | 인덱스·최적화로 대응 |

엑셀은 표를 그리는 도구, DB는 규칙과 관계로 저장·조회하는 시스템입니다.

#### Q2. 왜 테이블을 나눠서 저장하나요?

**A.** **중복을 줄이고, 수정을 한 곳에서** 하기 위해서입니다.  
카테고리명을 `course`마다 문자열로 넣으면 이름 변경 시 모든 행을 고쳐야 하고 `Backend`/`backend` 같은 불일치가 납니다.  
`category`를 분리하고 `course.category_id`로 연결하면 카테고리명은 **한 곳만** 수정하면 됩니다. (정규화의 기본)

#### Q3. RDBMS란?

**A.** Relational Database Management System — 관계형 데이터베이스 관리 시스템.  
데이터를 테이블(행·열)로 저장하고 SQL로 조회·수정합니다. MySQL, PostgreSQL, SQLite, Oracle 등.

#### Q4. SQL이란?

**A.** Structured Query Language — 관계형 DB에서 정의(DDL), 조작(DML), 조회(DQL)하는 표준 언어.  
백엔드 없이도 검색·정렬·집계 요구를 DB에 직접 풀 수 있습니다.

---

### 2. 데이터 모델링 & 관계

#### Q5. PK(Primary Key)란?

**A.** 테이블에서 **각 행을 유일하게 식별**하는 컬럼(또는 조합). NULL·중복 불가. 보통 `id INT AUTO_INCREMENT`.  
예: `member.id = 3` → `park_sql` 한 명.

#### Q6. FK(Foreign Key)란?

**A.** **다른 테이블의 PK를 참조**하는 컬럼. 관계를 DB 수준에서 연결하고, 없는 부모 ID로의 자식 INSERT를 막습니다.

```text
enrollment.member_id → member.id
enrollment.course_id → course.id
course.category_id   → category.id
```

#### Q7. 1:N 관계란?

**A.** 부모 하나 · 자식 여러 개. FK는 **항상 자식(N) 쪽**에 둡니다.

| 관계 | 부모 (1) | 자식 (N) |
|------|----------|----------|
| 카테고리 → 강의 | `category` | `course` |
| 회원 → 수강 | `member` | `enrollment` |
| 강의 → 수강 | `course` | `enrollment` |

#### Q8. N:M(다대다)은 어떻게 표현하나?

**A.** 중간 테이블(junction)을 둡니다. `member` ↔ `course`는 `enrollment`로 연결하고, `(member_id, course_id)` UNIQUE로 중복 수강을 막습니다.

```text
member (1) ──< enrollment >── (1) course
```

#### Q9. ERD란?

**A.** Entity Relationship Diagram — 테이블과 관계를 그림으로 표현한 것.  
본 프로젝트는 `erd.dbml`을 [dbdiagram.io](https://dbdiagram.io)에 붙여 시각화합니다.

---

### 3. 제약조건 & 무결성

#### Q10. NOT NULL, UNIQUE, CHECK 차이는?

| 제약 | 의미 | 본 프로젝트 예시 |
|------|------|------------------|
| NOT NULL | 빈 값 금지 | `member.email` |
| UNIQUE | 중복 금지 | `member.email`, `(member_id, course_id)` |
| CHECK | 조건 검사 | `progress_pct` 0–100, `tier IN (...)` |
| FK | 참조 무결성 | `member_id` → `member.id` |

#### Q11. FK 에러(ERROR 1452)가 나는 이유는?

**A.** 자식이 **존재하지 않는 부모 PK**를 참조할 때.  
해결: 부모에 해당 ID가 있는지 확인. INSERT 순서: `category` → `member` → `course` → `enrollment`.

#### Q12. ON DELETE RESTRICT / ON UPDATE CASCADE란?

**A.**

- **RESTRICT:** 자식이 있으면 부모 삭제/변경을 막음  
- **CASCADE (UPDATE):** 부모 PK 변경 시 자식 FK도 같이 갱신  

본 프로젝트는 `ON DELETE RESTRICT`로 회원·강의 무단 삭제를 막습니다.

#### Q13. 데이터 무결성이란?

**A.** 데이터가 규칙·관계에 맞게 유지되는 상태.

- 개체 무결성: PK 유일·NOT NULL  
- 참조 무결성: FK가 실제 값만 참조  
- 도메인 무결성: CHECK·타입으로 값 범위 준수  

---

### 4. SQL 기본 (CRUD)

#### Q14. SELECT / INSERT / UPDATE / DELETE 차이?

| 명령 | 용도 |
|------|------|
| SELECT | 조회 (데이터 변경 없음) |
| INSERT | 삽입 (새 회원·수강 등) |
| UPDATE | 수정 (진도·상태 변경) — WHERE 필수 |
| DELETE | 삭제 (취소 수강 정리 등) — WHERE 필수 |

#### Q15. WHERE, ORDER BY, LIMIT 역할은?

- **WHERE:** 조건 필터 (`tier = 'PRO'`)  
- **ORDER BY:** 정렬 (`price DESC`)  
- **LIMIT:** 개수 제한 (`LIMIT 5`)  

#### Q16. INSERT 순서가 왜 중요한가?

**A.** FK 때문에 **부모 데이터가 먼저** 있어야 합니다.  
`category` → `member` → `course` → `enrollment`.

---

### 5. JOIN

#### Q17. JOIN이란?

**A.** FK로 연결된 여러 테이블을 **한 결과 집합**으로 합치는 것.  
예: 회원 닉네임 + 수강 강의 제목.

#### Q18. INNER JOIN vs LEFT JOIN 차이?

| | INNER JOIN | LEFT JOIN |
|---|------------|-----------|
| 결과 | 양쪽 매칭되는 행만 | 왼쪽 전부 + 오른쪽 매칭 |
| 매칭 없을 때 | 제외 | 왼쪽 유지, 오른쪽 NULL |

- INNER (#5–#7): 수강이 **있는** 경우만  
- LEFT (#8–#9): **모든 회원/강의** + 건수 0 포함 (`bae_guest`)

#### Q19. JOIN을 여러 개 쓸 수 있나?

**A.** 가능. 쿼리 #5처럼 3테이블 JOIN:

```sql
FROM enrollment e
INNER JOIN member m ON e.member_id = m.id
INNER JOIN course c ON e.course_id = c.id
```

---

### 6. 집계 & GROUP BY

#### Q20. GROUP BY란?

**A.** 특정 컬럼으로 행을 묶고, 그룹마다 COUNT/SUM/AVG 등을 계산합니다.

```sql
SELECT c.title, COUNT(e.id) AS total
FROM course c
LEFT JOIN enrollment e ON c.id = e.course_id
GROUP BY c.id, c.title;
```

#### Q21. COUNT / SUM / AVG 차이?

| 함수 | 의미 | 본 프로젝트 |
|------|------|-------------|
| COUNT | 행 개수 | 강의별 수강 건수 (#10) |
| SUM | 합계 | tier별 강의 가격 합 (#12) |
| AVG | 평균 | 카테고리별 평균 진도 (#11) |

LEFT JOIN 후 0건을 보려면 `COUNT(e.id)`를 씁니다. `COUNT(*)`는 매칭 없는 행도 1로 셉니다.

#### Q22. HAVING vs WHERE 차이?

- **WHERE:** GROUP BY **전** — 개별 행 필터  
- **HAVING:** GROUP BY **후** — 그룹(집계) 단위 필터  

---

### 7. 서브쿼리

#### Q23. 서브쿼리란?

**A.** SQL 안에 또 다른 SELECT를 넣는 방식. 예: 수강 없는 회원 (#13).

```sql
SELECT id, email, nickname
FROM member
WHERE id NOT IN (
    SELECT DISTINCT member_id FROM enrollment
);
```

#### Q24. JOIN vs 서브쿼리, 언제 뭘 쓰나?

| | JOIN | 서브쿼리 |
|---|------|----------|
| 가독성 | 관계가 명확할 때 | 존재 여부 체크에 직관적 |
| 용도 | 여러 테이블 컬럼을 같이 출력 | 필터링, EXISTS / NOT IN |
| 성능 | 대체로 JOIN이 유리한 경우 많음 | 데이터·DB에 따라 다름 |

같은 요구를 두 방식으로 풀어 **결과가 같은지** 비교하는 것이 보너스(`bonus_join_subquery`) 목표입니다.

---

### 8. 인덱스

#### Q25. 인덱스란? 왜 필요한가?

**A.** 데이터를 **빠르게 찾기 위한 색인(목차)**.  
목차 없이 전 페이지를 넘기는 것 = Full Table Scan. 인덱스가 있으면 검색·정렬·JOIN이 빨라질 수 있습니다.

#### Q26. 어떤 컬럼에 인덱스를 걸까?

후보:

- WHERE에 자주 쓰는 컬럼 (`enrolled_at`)  
- JOIN 키 (FK는 InnoDB가 자동 인덱스)  
- ORDER BY에 자주 쓰는 컬럼  
- **카디널리티(고유값 수)** 가 높은 컬럼  

본 프로젝트: `CREATE INDEX idx_enrollment_enrolled_at ON enrollment (enrolled_at)`  
→ 최근 N일 수강, 기간별 추이 조회에 유리.

#### Q27. 인덱스 단점은?

**A.** INSERT/UPDATE/DELETE 시 인덱스 갱신 비용, 디스크 추가 사용. 모든 컬럼에 거는 것은 비효율.

---

### 9. 과제 제출물 관련

#### Q28. 제출해야 하는 파일은?

| 파일 | 내용 |
|------|------|
| `sql/01_schema.sql` | CREATE TABLE, PK/FK/제약 |
| `sql/02_insert_sample_data.sql` | INSERT (테이블당 10행+) |
| `sql/03_queries.sql` | 핵심 쿼리 15개+ |
| `results/` | 실행 결과 텍스트 |
| (선택) `erd.dbml` | ERD |

#### Q29. 최소 4개 테이블, 1:N 2개 이상 — 본 프로젝트는?

- 테이블 4개: `category`, `member`, `course`, `enrollment`  
- 1:N 3개: category→course, member→enrollment, course→enrollment  

#### Q30. 쿼리 15개 범주별로 몇 개씩?

| 범주 | 최소 | 본 프로젝트 |
|------|------|-------------|
| 기본 조회 | 4 | #1–4 |
| JOIN | 4 | #5–9 |
| 집계 | 3 | #10–12 |
| 서브쿼리 | 1 | #13 |
| UPDATE / DELETE | 2 | #14–15 |
| INDEX | 1 | #16 |

#### Q31. 백엔드 프레임워크 써도 되나?

**A.** 안 됩니다. **순수 SQL**만 제출합니다.

#### Q32. View, 프로시저, 트리거 써도 되나?

**A.** 과제 범위 밖. CREATE TABLE + INSERT + SELECT/JOIN/GROUP BY/UPDATE/DELETE/INDEX 안에서 작성합니다.

---

### 10. 본 프로젝트(Codyssey) 관련

#### Q33. 왜 코딩 학습 플랫폼 주제인가?

**A.** 회원·강의·카테고리·수강이 자연스럽게 1:N·N:M을 만들고, 인기 강의·진도율·tier 분석 같은 실무형 쿼리를 풀기 좋기 때문입니다.

#### Q34. enrollment 테이블 역할은?

**A.** `member`와 `course` 사이 **수강 신청 중간 테이블**.  
누가(`member_id`) 어떤 강의(`course_id`)를 언제(`enrolled_at`) 들었고, 진도(`progress_pct`)·상태(`status`)가 어떤지 저장합니다.

#### Q35. (member_id, course_id) UNIQUE를 둔 이유?

**A.** 같은 회원이 같은 강의를 **중복 수강 신청**하지 못하게 하기 위함입니다.

#### Q36. tier 컬럼(FREE/PRO/ENTERPRISE)은 왜?

**A.** 등급별 분석용. 예: PRO 회원 목록(#1), tier별 수강 강의 가격 합(#12).

#### Q37. progress_pct와 status를 같이 두는 이유?

**A.** 진도(숫자)와 상태(ACTIVE/COMPLETED/CANCELLED)는 다른 개념입니다.  
진도 100%여도 ACTIVE일 수 있음 → #14에서 COMPLETED로 UPDATE. CANCELLED는 #15에서 DELETE.

#### Q38. 핵심 지표 3개(보너스)는?

1. 카테고리별 수강 건수 — 인기 카테고리  
2. 강의별 수강 TOP 10 + 평균 진도 — 베스트셀러  
3. PRO 회원 평균 진도율 — 유료 회원 참여도  

파일: `sql/05_bonus_metrics.sql`, 결과: `results/bonus_metrics.txt`.

---

### 11. 개발 환경 (Docker / MySQL)

#### Q39. 왜 Docker로 MySQL을 띄웠나?

- PC에 MySQL 직접 설치 없이 동일 환경 재현  
- `docker compose down -v`로 초기화 쉬움  
- MySQL 8.4 버전을 팀·강사와 맞춤  

#### Q40. docker compose up / down 차이?

```powershell
docker compose up -d      # 시작
docker compose down       # 중지 (볼륨 유지)
docker compose down -v    # 중지 + 볼륨 삭제 (DB 초기화)
```

#### Q41. 연결 정보는?

| 항목 | 값 |
|------|-----|
| Host | `localhost` |
| Port | `3306` |
| Database | `codyssey` |
| User | `codyssey` |
| Password | `codyssey` |

#### Q42. sql/init/ 폴더는?

**A.** Docker MySQL **최초 기동** 시 자동 실행되는 SQL 위치. 볼륨이 있으면 다시 안 돕니다.  
재적용: `01_schema.sql` / `02_insert_sample_data.sql` 수동 실행, 또는 `capture_results.ps1`.

#### Q43. 한글이 깨질 때?

- SQL 파일 UTF-8  
- `--default-character-set=utf8mb4`  
- PowerShell 직접 리다이렉트 대신 컨테이너 파일 → `docker cp` (`capture_results.ps1`)  
- DB: `utf8mb4` / `utf8mb4_unicode_ci`  

---

### 12. ORM / JPA 연결

#### Q44. 이 과제와 JPA/ORM은 무슨 관련?

**A.** ORM이 하는 일(매핑·FK·JOIN)을 **SQL로 먼저 이해**하기 위한 과제입니다. 제출은 SQL만.

| SQL | JPA |
|-----|-----|
| PK | `@Id` |
| FK / 1:N | `@ManyToOne`, `@OneToMany` |
| JOIN | JPQL, `fetch join` |
| UNIQUE | `@Column(unique = true)` |

#### Q45. @OneToMany / @ManyToOne은 SQL로 보면?

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

#### Q46. N+1 문제란? (심화)

**A.** 1:N 조회 시 부모 1번 + 자식 N번 쿼리가 나가는 비효율.  
SQL은 JOIN 한 번으로 해결. JPA는 `fetch join` / `@EntityGraph`.

---

### 13. 보너스 과제 관련

#### Q47. FK 에러를 일부러 내는 이유?

**A.** FK가 **실제로 동작**함을 증명하고, 에러 메시지(1452)를 읽고 원인·해결을 설명하기 위함.  
`results/bonus_fk_error.txt`.

#### Q48. JOIN과 서브쿼리로 같은 결과를 내면?

**A.** 논리적으로 같은 집합이면 OK. 성능·실행 계획은 데이터에 따라 다를 수 있음.  
「결과 동일 + 가독성 + 언제 무엇을 쓸지」를 설명하면 좋습니다.

#### Q49. 발표/리뷰에서 자주 나올 질문 TOP 5?

1. 왜 테이블을 4개로 나눴는지  
2. FK가 없으면 어떤 문제가 생기는지  
3. INNER JOIN과 LEFT JOIN 차이 (예시)  
4. GROUP BY를 쓴 이유  
5. 인덱스를 그 컬럼에 건 이유  

#### Q50. 과제를 마치면 할 수 있게 된 것?

- DB와 엑셀 차이 설명  
- PK/FK, 1:N을 말로 설명  
- SELECT/INSERT/UPDATE/DELETE 구분  
- JOIN, GROUP BY로 연결 데이터 조회  
- 검색·정렬·집계·랭킹을 SQL로 풀기  
- 인덱스 필요성과 컬럼 선택 기준  

---

### 부록: SQL 치트시트

```sql
-- 조회
SELECT ... FROM ... WHERE ... ORDER BY ... LIMIT ...;

-- 삽입 (부모 먼저)
INSERT INTO table (col1, col2) VALUES (v1, v2);

-- 수정 / 삭제 (WHERE 필수)
UPDATE table SET col = val WHERE id = 1;
DELETE FROM table WHERE status = 'CANCELLED';

-- JOIN
FROM a INNER JOIN b ON a.id = b.a_id
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
