-- ============================================================
-- Slice 12: get_classroom_members RPC
-- 教師用此 RPC 取得班級成員 + email(繞過 auth.users RLS)
-- ============================================================

CREATE OR REPLACE FUNCTION get_classroom_members(p_classroom_id uuid)
RETURNS TABLE (
  id uuid,
  classroom_id uuid,
  student_id uuid,
  student_email text,
  joined_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 驗證呼叫者是這個班級的教師
  IF NOT EXISTS (
    SELECT 1 FROM classrooms
    WHERE id = p_classroom_id AND teacher_id = auth.uid()
  ) THEN
    RAISE EXCEPTION '無權存取此班級成員' USING ERRCODE = 'P0003';
  END IF;

  RETURN QUERY
  SELECT
    cm.id,
    cm.classroom_id,
    cm.student_id,
    u.email::text AS student_email,
    cm.joined_at
  FROM classroom_members cm
  JOIN auth.users u ON u.id = cm.student_id
  WHERE cm.classroom_id = p_classroom_id
  ORDER BY cm.joined_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_classroom_members(uuid) TO authenticated;
