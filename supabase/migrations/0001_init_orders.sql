-- Vineyard Cafe 주문 시스템 초기 마이그레이션
-- Supabase 대시보드 > SQL Editor 에서 이 파일 전체를 붙여넣고 실행하세요.

-- 1) 주문 테이블
-- id는 identity(자동 증가) 컬럼이라 이 값이 곧 "주문번호"로 쓰입니다.
create table if not exists public.orders (
  id            bigint generated always as identity primary key,
  customer_name text not null,
  items         jsonb not null,
  pickup_time   text not null,
  status        text not null default 'waiting' check (status in ('waiting', 'making', 'done')),
  created_at    timestamptz not null default now()
);

-- 2) RLS(Row Level Security) 켜기
-- 이걸 켜지 않으면 기본적으로 "테이블 권한이 있는 누구나 전체 접근 가능" 상태라
-- anon key만 쓰는 이 앱에서는 반드시 켜야 합니다.
alter table public.orders enable row level security;

-- 3) anon 역할에 대한 정책(policy)
-- 로그인이 없으므로 모든 손님/바리스타 요청은 "anon" 역할로 들어옵니다.

-- 손님이 새 주문을 넣을 수 있어야 함
drop policy if exists "anon can insert orders" on public.orders;
create policy "anon can insert orders"
  on public.orders
  for insert
  to anon
  with check (true);

-- 손님(자기 주문 상태 추적)과 바리스타(대기열 보기) 둘 다 읽기가 필요함
drop policy if exists "anon can select orders" on public.orders;
create policy "anon can select orders"
  on public.orders
  for select
  to anon
  using (true);

-- 바리스타가 상태를 바꿀 수 있어야 함 (waiting -> making -> done)
-- 주의: RLS 정책 자체는 "어떤 컬럼을 바꿀 수 있는지"는 제한하지 못합니다.
-- 그래서 아래 4번에서 컬럼 단위 권한(GRANT)으로 status 컬럼만 수정 가능하게 막습니다.
drop policy if exists "anon can update orders" on public.orders;
create policy "anon can update orders"
  on public.orders
  for update
  to anon
  using (true)
  with check (true);

-- 4) 컬럼 단위 권한: anon은 오직 status만 UPDATE 가능
-- (이름/메뉴/시간을 나중에 몰래 바꾸는 것을 막기 위함)
revoke update on public.orders from anon;
grant update (status) on public.orders to anon;

-- select/insert는 Supabase가 기본으로 열어주지만, 명시적으로 한 번 더 보장
grant select, insert on public.orders to anon;

-- 5) Realtime 활성화
-- 이 테이블의 변경사항(INSERT/UPDATE)을 realtime으로 구독할 수 있게 publication에 추가
alter publication supabase_realtime add table public.orders;
