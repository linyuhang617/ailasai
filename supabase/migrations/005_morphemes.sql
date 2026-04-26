-- ============================================================
-- Migration 005 — morphemes + word_morphemes
-- ============================================================

-- 1. morphemes：字根/字首/字尾資料（由 Directus CMS 管理）
CREATE TABLE IF NOT EXISTS public.morphemes (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  form        text        NOT NULL,
  type        text        NOT NULL CHECK (type IN ('prefix', 'root', 'suffix')),
  meaning_zh  text        NOT NULL,
  language    text        NOT NULL DEFAULT 'en',
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 2. word_morphemes：單字與字根的關聯（含順序）
CREATE TABLE IF NOT EXISTS public.word_morphemes (
  id           uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  word_id      uuid    NOT NULL REFERENCES public.words(id) ON DELETE CASCADE,
  morpheme_id  uuid    NOT NULL REFERENCES public.morphemes(id) ON DELETE CASCADE,
  position     integer NOT NULL,
  UNIQUE (word_id, morpheme_id, position)
);

-- 3. index
CREATE INDEX IF NOT EXISTS idx_word_morphemes_word_id
  ON public.word_morphemes (word_id, position);

-- 4. RLS
ALTER TABLE public.morphemes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.word_morphemes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "morphemes_select_authenticated"
  ON public.morphemes FOR SELECT TO authenticated USING (true);

CREATE POLICY "word_morphemes_select_authenticated"
  ON public.word_morphemes FOR SELECT TO authenticated USING (true);
