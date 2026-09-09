// Supabase 프로젝트 연결 정보.
// anon key는 "공개되어도 되는" 키입니다 (브라우저에서 그대로 노출됨).
// 대신 실제 보안은 DB의 RLS 정책이 담당합니다 — 0001_init_orders.sql 참고.
//
// 아래 두 값은 Supabase 대시보드 > Project Settings > API 에서 확인할 수 있습니다.
//   - SUPABASE_URL  : "Project URL"
//   - SUPABASE_ANON_KEY : "anon public" 키
window.SUPABASE_CONFIG = {
  url: "https://nssmtqtuxrlyophpslub.supabase.co",
  anonKey: "sb_publishable_cH5ABA5hDiLM3Run4YINgQ_XNfiWXNH",
};
