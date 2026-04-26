-- Slice 10 引入 FSRS 時遺漏的 server 欄位
-- TECH-DEBT-1 清償:補 stability / difficulty, 讓 pushSingleCardState 能完整帶 FSRS 參數
-- 預設 0 對應 Isar CardState 的 double stability/difficulty = 0.0

ALTER TABLE public.card_states
  ADD COLUMN IF NOT EXISTS stability  double precision NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS difficulty double precision NOT NULL DEFAULT 0;
