# Vineyard Cafe 주문 웹앱

정적 HTML/CSS/JS + Supabase(Postgres + Realtime) 조합. 로그인·결제 없음.

## 파일 구성

- `index.html` — 손님용 주문 화면
- `barista.html` — 바리스타용 대기열 화면
- `config.js` — Supabase 프로젝트 연결 정보 (직접 채워야 함)
- `supabase/migrations/0001_init_orders.sql` — DB 테이블 + RLS 정책

---

## 1. 당신이 직접 해야 하는 단계 (Supabase 대시보드)

### 1-1. 프로젝트 생성
1. [supabase.com](https://supabase.com) 에서 새 프로젝트 생성 (무료 플랜으로 충분)
2. 프로젝트가 준비되면 왼쪽 메뉴 **SQL Editor** 로 이동

### 1-2. 테이블 + RLS 생성
1. `supabase/migrations/0001_init_orders.sql` 파일 내용을 전체 복사
2. SQL Editor에 붙여넣고 **Run**
3. 왼쪽 메뉴 **Table Editor**에서 `orders` 테이블이 생겼는지 확인

### 1-3. Realtime 확인
마이그레이션 안에 `alter publication supabase_realtime add table public.orders;` 가 이미 포함되어 있어서 보통 별도 설정이 필요 없습니다. 혹시 실시간이 안 되면:
- **Database > Replication** 메뉴에서 `orders` 테이블이 `supabase_realtime` publication에 포함되어 있는지 확인하세요.

### 1-4. API 키 확인
**Project Settings > API** 에서 아래 두 값을 복사:
- `Project URL`
- `anon public` 키 (⚠️ `service_role` 키는 절대 사용하지 마세요 — 이건 서버 전용 키라 RLS를 무시합니다)

### 1-5. config.js 채우기
`config.js`를 열어 URL과 anon key를 붙여넣으세요:

```js
window.SUPABASE_CONFIG = {
  url: "https://xxxxxxxx.supabase.co",
  anonKey: "eyJhbGciOi...",
};
```

### 1-6. Supabase 자동 정지(pause) 막기 — GitHub Actions 시크릿 등록

Supabase 무료 플랜은 **7일 동안 API 요청이 없으면 프로젝트가 자동으로 일시정지**됩니다. 정지되면 대시보드에서 수동으로 "Restore"를 눌러야 다시 살아나요. 이 앱은 주일에만 쓰이기 때문에 방치하면 딱 그 주기와 겹쳐서 필요할 때 먹통일 수 있습니다.

그래서 `.github/workflows/keep-alive.yml` 워크플로우가 매주 월/목 자동으로 가벼운 조회 요청을 보내 정지를 막습니다. 이게 동작하려면 GitHub 저장소에 시크릿 2개를 등록해야 합니다 (1-4에서 복사한 값과 동일):

1. GitHub 저장소 **Settings > Secrets and variables > Actions**
2. **New repository secret**으로 아래 2개 추가
   - `SUPABASE_URL` → Project URL
   - `SUPABASE_ANON_KEY` → anon public 키
3. **Actions** 탭 > **Supabase Keep-Alive** > **Run workflow**로 한 번 수동 실행해서 성공하는지(초록 체크) 확인

이후로는 별도 관리 없이 자동으로 주기적으로 깨어있는 상태가 유지됩니다.

---

## 2. 로컬에서 테스트

빌드 도구가 없으니 그냥 파일을 열어도 되지만, 브라우저 보안 정책 때문에 로컬 서버로 여는 걸 추천합니다:

```bash
cd vineyard-cafe
python3 -m http.server 8080
```

브라우저에서 `http://localhost:8080` (손님 화면), `http://localhost:8080/barista.html` (바리스타 화면)을 각각 열어 테스트하세요.

---

## 3. GitHub Pages 배포

1. 이 폴더를 새 GitHub 저장소에 push
2. 저장소 **Settings > Pages**
3. **Source**를 `main` 브랜치 / `/ (root)` 로 설정 후 저장
4. 몇 분 후 `https://<username>.github.io/<repo>/` 로 접속 가능
5. 주보 QR코드는 `https://<username>.github.io/<repo>/index.html` 로 만들고, 바리스타 태블릿에는 `.../barista.html`을 즐겨찾기/홈 화면에 추가해두세요

`config.js`는 **.gitignore에 넣지 말고 그대로 커밋**하세요. anon key는 브라우저에 그대로 노출되는 게 원래 설계이고, 실제 접근 제어는 RLS가 담당합니다 (아래 4번 참고).

---

## 4. 왜 이렇게 만들었는지 (핵심 결정 설명)

**anon key가 공개돼도 안전한 이유**
Supabase의 `anon` key는 "이 사람이 누군지"가 아니라 "로그인 안 한 익명 사용자"라는 역할만 나타냅니다. 실제 권한은 DB의 Row Level Security(RLS) 정책이 결정합니다. 그래서 키 자체를 숨기는 게 아니라, **정책을 정확히 걸어두는 게** 진짜 보안입니다.

**RLS 정책 3가지 + 컬럼 권한 1가지**
- `select`, `insert`는 누구나(anon) 가능 — 로그인이 없으니 당연히 필요
- `update`는 정책상 "가능"하지만, Postgres의 컬럼 단위 `GRANT`로 **`status` 컬럼만** 고칠 수 있게 막아뒀습니다. RLS 정책 자체는 "어떤 컬럼"까지는 제한 못 해서, `revoke update ... / grant update (status) ...` 조합을 쓴 겁니다. 이렇게 하면 바리스타 화면(또는 누구든)이 이름이나 메뉴를 몰래 바꾸는 게 원천적으로 막힙니다.
- `delete` 정책은 아예 만들지 않았습니다 → anon은 주문을 지울 수 없습니다.

**주문 확인 카드가 realtime을 쓰는 이유**
손님이 화면을 계속 새로고침하지 않아도 "대기 → 제조중 → 완료"가 자동으로 바뀌어 보이게 하려고, 자기 주문 id 하나만 필터링해서 구독합니다 (`filter: id=eq.<주문번호>`). 전체 테이블을 구독하지 않으니 가볍습니다.

**바리스타 화면의 realtime + 폴링 폴백**
Wi-Fi가 불안정한 예배당 환경을 감안해서, realtime 구독이 끊기면(`CHANNEL_ERROR`/`TIMED_OUT`/`CLOSED`) 자동으로 5초 폴링으로 전환하고, 재연결되면 폴링을 멈춥니다. 화면 상단 배지로 지금 어떤 모드인지 보여줍니다.

**"묶어서 만들 음료"가 대기(waiting) 주문만 합산하는 이유**
이미 제조 중인 음료까지 합치면 바리스타가 "지금부터 몇 잔 더 만들면 되는지" 헷갈리게 됩니다. 그래서 아직 손 안 댄 대기열만 메뉴+온도 기준으로 합산해서 보여줍니다.

**낙관적(optimistic) 업데이트**
바리스타가 "제조 시작"/"완료" 버튼을 누르면 서버 응답을 기다리지 않고 화면을 먼저 바꿉니다 (태블릿에서 버튼 반응이 느리면 여러 번 누르게 되는 걸 방지). 실패하면 원래 상태로 되돌리고 알림을 띄웁니다.

---

## 5. RLS가 실제로 걸려있는지 검증하는 법

터미널에서 anon key로 직접 다른 컬럼(예: `customer_name`)을 바꾸려고 시도해보세요. `<URL>`과 `<ANON_KEY>`를 채우고, 실제 존재하는 주문 `id`를 하나 넣어 실행하면:

```bash
curl -X PATCH "https://<URL>.supabase.co/rest/v1/orders?id=eq.1" \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"customer_name":"해킹시도"}'
```

정상적으로 막혀 있다면 `permission denied for column customer_name` 같은 에러가 나야 합니다. 대신 `{"status":"making"}` 으로 바꾸는 요청은 성공해야 합니다. 둘 다 확인해서 의도한 대로 막혀있는지 꼭 테스트해보세요.

---

## 6. 메뉴/가격을 바꾸고 싶을 때

`index.html`의 `MENU` 배열과, `barista.html`의 픽업 옵션 등은 각 파일 상단 `<script>`에서 상수로 관리됩니다. 빌드 과정이 없으니 값만 고쳐서 다시 GitHub에 push하면 바로 반영됩니다.
