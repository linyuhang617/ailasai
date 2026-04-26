-- ============================================================
-- Slice 12: Classrooms + Classroom Members
-- ============================================================

-- ------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------

CREATE TABLE classrooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  teacher_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invite_code text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX classrooms_teacher_id_idx ON classrooms(teacher_id);
CREATE INDEX classrooms_invite_code_idx ON classrooms(invite_code);

CREATE TABLE classroom_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  classroom_id uuid NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (classroom_id, student_id)
);

CREATE INDEX classroom_members_classroom_id_idx ON classroom_members(classroom_id);
CREATE INDEX classroom_members_student_id_idx ON classroom_members(student_id);

-- ------------------------------------------------------------
-- RLS
-- ------------------------------------------------------------

ALTER TABLE classrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE classroom_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teachers manage own classrooms"
ON classrooms FOR ALL
TO authenticated
USING (teacher_id = auth.uid())
WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Students read joined classrooms"
ON classrooms FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT classroom_id FROM classroom_members
    WHERE student_id = auth.uid()
  )
);

CREATE POLICY "Teachers read own classroom members"
ON classroom_members FOR SELECT
TO authenticated
USING (
  classroom_id IN (
    SELECT id FROM classrooms WHERE teacher_id = auth.uid()
  )
);

CREATE POLICY "Teachers remove own classroom members"
ON classroom_members FOR DELETE
TO authenticated
USING (
  classroom_id IN (
    SELECT id FROM classrooms WHERE teacher_id = auth.uid()
  )
);

CREATE POLICY "Students read own memberships"
ON classroom_members FOR SELECT
TO authenticated
USING (student_id = auth.uid());

CREATE POLICY "Students leave classroom"
ON classroom_members FOR DELETE
TO authenticated
USING (student_id = auth.uid());

-- ------------------------------------------------------------
-- RPC:學生用邀請碼加入班級
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION join_classroom_by_invite_code(p_invite_code text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_classroom_id uuid;
  v_teacher_id uuid;
BEGIN
  SELECT id, teacher_id
  INTO v_classroom_id, v_teacher_id
  FROM classrooms
  WHERE invite_code = p_invite_code;

  IF v_classroom_id IS NULL THEN
    RAISE EXCEPTION '邀請碼無效' USING ERRCODE = 'P0001';
  END IF;

  IF v_teacher_id = auth.uid() THEN
    RAISE EXCEPTION '不能加入自己建立的班級' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO classroom_members (classroom_id, student_id)
  VALUES (v_classroom_id, auth.uid())
  ON CONFLICT (classroom_id, student_id) DO NOTHING;

  RETURN v_classroom_id;
END;
$$;

GRANT EXECUTE ON FUNCTION join_classroom_by_invite_code(text) TO authenticated;
