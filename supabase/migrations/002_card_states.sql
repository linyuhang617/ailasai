-- card_states 建表
CREATE TABLE IF NOT EXISTS public.card_states (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  word_id         uuid NOT NULL,
  ease_factor     double precision NOT NULL DEFAULT 2.5,
  interval_days   integer NOT NULL DEFAULT 1,
  repetitions     integer NOT NULL DEFAULT 0,
  due_at          timestamptz NOT NULL DEFAULT now(),
  last_reviewed_at timestamptz NOT NULL DEFAULT now(),
  total_reviews   integer NOT NULL DEFAULT 0,
  correct_reviews integer NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, word_id)
);

-- RLS
ALTER TABLE public.card_states ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users can read own card_states"
  ON public.card_states FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "users can insert own card_states"
  ON public.card_states FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "users can update own card_states"
  ON public.card_states FOR UPDATE
  USING (auth.uid() = user_id);
