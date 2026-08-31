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

구술·복습용으로 `docs/QA_예상질문답변.md`에 다음을 모아 두었습니다.

- PK / FK / 1:N / N:M, CHECK·UNIQUE
- JOIN·GROUP BY·서브쿼리·인덱스
- 제출 파일 목록과 범주별 쿼리 개수
- Docker Compose, 문자셋
- SQL 개념과 JPA 매핑의 대응 (과제는 SQL만 제출)

---

## 평가 문항 대비 (답변 포함)

아래는 과제 **평가문항 항목 1~5**를 이 레포(Codyssey) 기준으로 풀어 쓴 답입니다.  
항목 1은 제출물 체크리스트, 항목 2~4는 구술 설명용, 항목 5는 보너스 크레딧입니다.

---

### 항목 1 — 제출물 체크 (구현 여부)

#### Q. 최소 4개 테이블이 존재하고, 각 테이블에 PK가 정의되어 있는가?

**A. 예.** `sql/01_schema.sql`에 4개 테이블이 있고, 모두 `id INT AUTO_INCREMENT`를 PRIMARY KEY로 둡니다.

| 테이블 | PK |
|--------|-----|
| `category` | `id` |
| `member` | `id` |
| `course` | `id` |
| `enrollment` | `id` |

#### Q. FK를 사용한 1:N 관계가 최소 2개 이상 존재하고, 없는 값 참조가 실제로 막히는가?

**A. 예.** 1:N은 3개입니다.

| 부모 (1) | 자식 (N) | FK 컬럼 |
|----------|----------|---------|
| `category` | `course` | `course.category_id` |
| `member` | `enrollment` | `enrollment.member_id` |
| `course` | `enrollment` | `enrollment.course_id` |

없는 값 참조는 DB가 막습니다. `member_id = 9999`로 INSERT하면:

```text
ERROR 1452 ... FOREIGN KEY (`member_id`) REFERENCES `member` (`id`)
```

증거: `results/bonus_fk_error.txt`, 재현용 SQL: `sql/04_bonus_fk_test.sql`.

#### Q. 각 테이블에 최소 10행 이상의 샘플 데이터가 입력되어 있는가?

**A. 예.** `sql/02_insert_sample_data.sql` 기준:

| 테이블 | 행 수 |
|--------|------|
| `category` | 12 |
| `member` | 12 |
| `course` | 14 |
| `enrollment` | 18 |

#### Q. 기본 조회(4개), 조인(4개), 집계(3개), 서브쿼리(1개), 수정/삭제(2개), 인덱스(1개)를 포함한 쿼리 15개가 작성되어 있는가?

**A. 예.** 실제로는 **16개**(인덱스까지 포함). 모음: `sql/03_queries.sql`.

| 범주 | 요구 | 본 프로젝트 |
|------|------|-------------|
| 기본 조회 | 4 | #1–#4 |
| JOIN | 4 | #5–#9 (INNER 3 + LEFT 2) |
| 집계 | 3 | #10–#12 |
| 서브쿼리 | 1 | #13 |
| UPDATE / DELETE | 2 | #14 / #15 |
| INDEX | 1 | #16 |

#### Q. 각 쿼리의 실행 결과가 스크린샷 또는 텍스트로 첨부되어 있는가?

**A. 예.** `results/query_01.txt` … `results/query_16_index.txt` 텍스트로 첨부.  
재생성: `powershell -File sql/capture_results.ps1`.

---

### 항목 2 — 설계 설명 (구술)

#### Q. 테이블을 왜 이렇게 나눴는지, 각 테이블의 역할을 말할 수 있는가?

**A.** 한 시트에 몰아넣으면 카테고리명·회원정보가 수강 행마다 반복되고, 수정 시 불일치가 납니다. 역할을 나눠 **중복을 줄이고 관계를 FK로 강제**합니다.

| 테이블 | 역할 |
|--------|------|
| `category` | 강의 분류 (Backend, Frontend 등) |
| `member` | 플랫폼 회원 (이메일, 등급 tier) |
| `course` | 개별 강의 (가격, 난이도, 카테고리 소속) |
| `enrollment` | 누가 어떤 강의를 언제·어느 진도로 수강했는지 (회원–강의 연결) |

#### Q. FK로 연결한 1:N 관계가 실제 도메인에서 어떤 의미인지 예시를 들어 보여줄 수 있는가?

**A.**

1. **category 1 : N course** — 「Backend」 카테고리 하나에 「Spring Boot REST API」「JPA와 Hibernate」 여러 강의가 속함.  
   `course.category_id = category.id`
2. **member 1 : N enrollment** — `kim_dev` 한 명이 여러 강의를 수강함.  
   `enrollment.member_id = member.id`
3. **course 1 : N enrollment** — 「SQL과 데이터 모델링 기초」 한 강의에 여러 회원이 신청함.  
   `enrollment.course_id = course.id`

회원과 강의는 서로 다대다(N:M)이지만, 중간 테이블 `enrollment`로 풀었습니다.

#### Q. 컬럼 타입(TEXT, INTEGER, DATE 등)을 왜 그렇게 선택했는지 설명할 수 있는가?

**A.** (MySQL에서는 `TEXT` 대신 길이 제한이 있는 `VARCHAR`, 정수는 `INT`/`TINYINT`를 사용)

| 컬럼 | 타입 | 이유 |
|------|------|------|
| `id` | `INT AUTO_INCREMENT` | 행 식별용 정수 PK. 자동 증가로 충돌 방지 |
| `email`, `title` 등 | `VARCHAR(n)` | 짧은 문자열. 최대 길이로 과도한 입력 제한 (`TEXT`까지는 불필요) |
| `price` | `DECIMAL(10,2)` | 금액은 부동소수 오차를 피하기 위해 소수 고정 자릿수 |
| `progress_pct` | `TINYINT` | 0–100만 필요. 작은 정수면 충분 + CHECK로 범위 제한 |
| `joined_at`, `published_at` | `DATE` | 가입일·출간일은 시각까지 필요 없음 |
| `enrolled_at`, `created_at` | `DATETIME` | 수강 시각·생성 시각은 시분초까지 기록 |
| `tier`, `level`, `status` | `VARCHAR` + `CHECK` | 허용 값만 들어가게 열거형처럼 제한 |

#### Q. 인덱스를 어떤 컬럼에 걸었고, 왜 그 컬럼이어야 하는지 이유를 대답할 수 있는가?

**A.** `enrollment.enrolled_at`에 `idx_enrollment_enrolled_at`를 걸었습니다. (`sql/queries/16_create_index.sql`)

- **WHERE / ORDER BY**에 자주 쓸 컬럼: 「최근 30일 수강」「기간별 추이」
- FK인 `member_id`, `course_id`는 InnoDB가 **이미 인덱스**를 만듦 → 중복으로 걸 필요 없음
- 카디널리티가 높은 시각 컬럼이라, 기간 필터 시 Full Table Scan을 줄일 여지가 있음
- 단점: INSERT/UPDATE 시 인덱스 갱신 비용·디스크 사용 → 자주 검색하는 컬럼에만 선택적으로 적용

---

### 항목 3 — 개념 + 본인 스키마로 설명

#### Q. 데이터베이스가 엑셀과 무엇이 다른지, 왜 테이블을 나눠 저장하는지 비교하며 설명할 수 있는가?

**A.**

| | 엑셀 | DB (본 과제) |
|---|------|----------------|
| 관계 | 사람이 셀로 맞춰 봄 | FK로 **없는 부모 참조를 거부** |
| 중복 | 복사·붙여넣기로 반복되기 쉬움 | 정규화로 **한 곳만 수정** |
| 동시성 | 파일 공유 시 충돌 | 트랜잭션으로 안전하게 처리 |
| 조회 | 필터·피벗을 수동 | SQL로 JOIN·집계를 **재현 가능하게** |

테이블을 나눈 이유: 카테고리명을 `course`마다 문자열로 넣으면 「Backend」 오타·표기 불일치가 생기고, 이름 변경 시 모든 행을 고쳐야 합니다. `category`로 분리하면 `name` 한 줄만 바꾸면 됩니다.

#### Q. PK와 FK의 역할을 구분하고, 1:N 관계가 데이터를 어떻게 연결하는지 본인 스키마 기준으로 보여줄 수 있는가?

**A.**

- **PK**: 그 테이블 안에서 행을 유일하게 가리킴. 예) `member.id = 1` → `kim_dev` 한 명.
- **FK**: **다른 테이블의 PK를 가리키는 값**. 예) `enrollment.member_id = 1` → 그 수강 행은 `kim_dev`의 것.

연결 예:

```text
member.id = 1 (kim_dev)
    └─ enrollment (member_id=1, course_id=1)  →  course.id = 1 (Spring Boot REST API)
                                                      └─ category.id = 1 (Backend)
```

스키마상: 자식 행의 FK 값이 부모 PK와 같을 때 조인으로 한 줄로 펼칩니다.

#### Q. INNER JOIN과 LEFT JOIN의 차이를 실행 결과를 보며 짚어줄 수 있는가?

**A.**

- **INNER JOIN** (#5–#7): 양쪽 **모두 매칭되는 행만**. 수강이 없는 회원은 결과에 안 나옴.
- **LEFT JOIN** (#8–#9): **왼쪽(기준)은 전부**, 오른쪽이 없으면 NULL → `COUNT(e.id)`는 0.

대비 예시:

- #5 INNER: 수강 기록이 있는 경우만 닉네임·강의 제목 표시
- #8 LEFT: `bae_guest`처럼 수강 0건인 회원도 `enrollment_count = 0`으로 포함  
  결과 파일: `results/query_05.txt` vs `results/query_08.txt`

#### Q. GROUP BY와 집계 함수(COUNT, SUM, AVG)가 어떻게 동작하는지 쿼리 결과를 이야기할 수 있는가?

**A.** `GROUP BY`는 지정한 컬럼 값이 같은 행을 **한 그룹으로 묶고**, 그룹마다 집계 함수를 한 번 계산합니다.

| 쿼리 | 묶는 단위 | 집계 | 의미 |
|------|-----------|------|------|
| #10 | 강의 | `COUNT(e.id)` | 강의별 수강 신청 건수 TOP 10 |
| #11 | 카테고리 | `AVG(progress_pct)` | 카테고리별 평균 진도율 |
| #12 | 회원 tier | `SUM(price)` | 등급별로 「수강 중인 강의 가격」 합 |

예: #10에서 같은 `course_id`를 가진 enrollment 여러 행이 한 그룹이 되고, 그 개수가 `enrollment_count`입니다. SELECT에 올린 비집계 컬럼은 `GROUP BY`에 함께 넣습니다 (`c.id, c.title`).

---

### 항목 4 — 과정 회고 (구술)

#### Q. 작성한 쿼리 중 가장 복잡했던 쿼리를 선택하고, 어떻게 풀었는지 단계별로 설명할 수 있는가?

**A. (예시 답안 — 서브쿼리 #13 또는 보너스 JOIN vs 서브쿼리)**

**선택: #13 「한 번도 수강하지 않은 회원」**

1. 목표: `enrollment`에 한 줄도 없는 `member`를 찾기  
2. 안쪽: `SELECT DISTINCT member_id FROM enrollment` → 수강한 적 있는 회원 ID 집합  
3. 바깥: `member`에서 `id NOT IN (그 집합)`  
4. 검증: 샘플에 심어 둔 `bae_guest`가 결과에 나오는지 확인 (`results/query_13.txt`)

또는 **보너스** 「평균 이상 수강 건수 강의」:

1. 강의별 수강 건수를 센다 (`GROUP BY course_id`)  
2. 그 건수들의 평균을 구한다 (스칼라 서브쿼리)  
3. `HAVING COUNT(*) >= 평균`으로 필터  
4. 같은 결과를 INNER JOIN 방식과 상관 서브쿼리 방식으로 각각 작성해 비교 (`results/bonus_join_vs_subquery.txt`)

#### Q. 미션 수행 중 가장 어려웠던 부분과 해결 방법을 구체적으로 말할 수 있는가?

**A. (예시 답안 — 발표 시 본인 경험에 맞게 바꿔도 됨)**

1. **FK 삽입 순서** — `enrollment`를 먼저 넣으면 실패. **부모(category → member → course) 후 자식** 순서로 맞춤.  
2. **LEFT JOIN + COUNT** — `COUNT(*)`를 쓰면 매칭 없는 행도 1로 잡혀 0건 회원이 안 보임. **`COUNT(e.id)`**(NULL은 세지 않음)로 해결.  
3. **결과 한글 깨짐** — PowerShell에서 `docker exec` 출력을 바로 리다이렉트하면 깨짐. 컨테이너 안 파일로 쓰고 `docker cp`하는 `capture_results.ps1`로 통일.  
4. **UPDATE/DELETE와 결과 캡처 순서** — #14·#15가 데이터를 바꾸므로, 지표 보너스는 **샘플 원본 상태에서 먼저** 캡처하도록 스크립트 순서를 잡음.

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
