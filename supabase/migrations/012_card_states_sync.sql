-- Slice 16: card_states 雙向 sync 支援
--
-- 既有 schema 已經有 updated_at column (002 建表時就放了, 預設 now())
-- 但目前是 client 在 push 時自己塞 DateTime.now() 上去, 不可信
-- 本 migration 改為:
--   1. server trigger 自動蓋 updated_at, client 推什麼值都不算數
--   2. 加 index (user_id, updated_at) 給 incremental pull cursor
--   3. backfill 既有 row: updated_at < last_reviewed_at 的補齊
--      避免 cursor 第一次 pull 時漏掉早期資料

-- 1. trigger function: BEFORE UPDATE 自動蓋 updated_at
CREATE OR REPLACE FUNCTION public.set_card_states_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS card_states_set_updated_at ON public.card_states;

CREATE TRIGGER card_states_set_updated_at
  BEFORE UPDATE ON public.card_states
  FOR EACH ROW
  EXECUTE FUNCTION public.set_card_states_updated_at();

-- 2. INSERT 也要保證 updated_at = now() (避免 client 推一個過去時刻)
CREATE OR REPLACE FUNCTION public.set_card_states_updated_at_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS card_states_set_updated_at_insert ON public.card_states;

CREATE TRIGGER card_states_set_updated_at_insert
  BEFORE INSERT ON public.card_states
  FOR EACH ROW
  EXECUTE FUNCTION public.set_card_states_updated_at_insert();

-- 3. incremental pull index
CREATE INDEX IF NOT EXISTS card_states_user_updated_idx
  ON public.card_states (user_id, updated_at DESC);

-- 4. backfill: 既有 row 若 updated_at 落後 last_reviewed_at, 拉齊
--    這樣下次 client incremental pull 用 updated_at cursor 不會漏資料
--    注意: 直接 UPDATE 會觸發 trigger 把 updated_at 蓋成 now(),
--          所以這裡分兩步,先用 SECURITY DEFINER 暫時 disable trigger
ALTER TABLE public.card_states DISABLE TRIGGER card_states_set_updated_at;

UPDATE public.card_states
   SET updated_at = last_reviewed_at
 WHERE updated_at < last_reviewed_at;

ALTER TABLE public.card_states ENABLE TRIGGER card_states_set_updated_at;
