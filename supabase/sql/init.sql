-- Supabase SQL: create tables, relationships, and RLS policies
-- Replace schema names if needed. Run this in Supabase SQL editor.

-- Enable pgcrypto for gen_random_uuid
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Function to check admin role
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT EXISTS(SELECT 1 FROM public.user_roles WHERE user_id = auth.uid()::uuid AND role = 'admin');
$$;

-- Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  full_name text,
  email text,
  avatar_url text,
  bio text,
  created_at timestamptz DEFAULT now()
);

-- User roles
CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'user',
  assigned_at timestamptz DEFAULT now()
);

-- QA modules
CREATE TABLE IF NOT EXISTS public.qa_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  created_by uuid REFERENCES auth.users,
  created_at timestamptz DEFAULT now()
);

-- Test suites
CREATE TABLE IF NOT EXISTS public.test_suites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  module_id uuid REFERENCES public.qa_modules,
  created_by uuid REFERENCES auth.users,
  created_at timestamptz DEFAULT now()
);

-- Test cases
CREATE TABLE IF NOT EXISTS public.test_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  steps jsonb,
  expected_result text,
  suite_id uuid REFERENCES public.test_suites,
  created_by uuid REFERENCES auth.users,
  created_at timestamptz DEFAULT now()
);

-- Test plans
CREATE TABLE IF NOT EXISTS public.test_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  created_by uuid REFERENCES auth.users,
  created_at timestamptz DEFAULT now()
);

-- Test plan cases (many-to-many)
CREATE TABLE IF NOT EXISTS public.test_plan_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid REFERENCES public.test_plans ON DELETE CASCADE,
  case_id uuid REFERENCES public.test_cases ON DELETE CASCADE,
  ordering integer DEFAULT 0
);

-- Test executions
CREATE TABLE IF NOT EXISTS public.test_executions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid REFERENCES public.test_plans,
  executed_by uuid REFERENCES auth.users,
  status text DEFAULT 'not_started', -- not_started, running, passed, failed, blocked
  results jsonb,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Bugs
CREATE TABLE IF NOT EXISTS public.bugs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  status text DEFAULT 'open', -- open, in_progress, resolved, closed
  severity text DEFAULT 'minor',
  reported_by uuid REFERENCES auth.users,
  assigned_to uuid REFERENCES auth.users,
  related_execution uuid REFERENCES public.test_executions,
  created_at timestamptz DEFAULT now()
);

-- Activities (audit log)
CREATE TABLE IF NOT EXISTS public.activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users,
  action text NOT NULL,
  meta jsonb,
  created_at timestamptz DEFAULT now()
);

-- Simple view to expose user roles
CREATE VIEW IF NOT EXISTS public.v_user_roles AS
 SELECT u.id as user_id, ur.role
 FROM auth.users u
 LEFT JOIN public.user_roles ur ON ur.user_id = u.id;

-- Enable Row Level Security and Policies

-- Helper: allow authenticated users to read public-ish tables

ALTER TABLE public.qa_modules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qa_modules_select" ON public.qa_modules FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "qa_modules_insert" ON public.qa_modules FOR INSERT USING (auth.role() = 'authenticated') WITH CHECK (true);
CREATE POLICY "qa_modules_manage_self_or_admin" ON public.qa_modules FOR UPDATE, DELETE USING (public.is_admin() OR created_by = auth.uid()::uuid);

ALTER TABLE public.test_suites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "test_suites_select" ON public.test_suites FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "test_suites_insert" ON public.test_suites FOR INSERT USING (auth.role() = 'authenticated') WITH CHECK (true);
CREATE POLICY "test_suites_manage" ON public.test_suites FOR UPDATE, DELETE USING (public.is_admin() OR created_by = auth.uid()::uuid);

ALTER TABLE public.test_cases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "test_cases_select" ON public.test_cases FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "test_cases_insert" ON public.test_cases FOR INSERT USING (auth.role() = 'authenticated') WITH CHECK (true);
CREATE POLICY "test_cases_manage" ON public.test_cases FOR UPDATE, DELETE USING (public.is_admin() OR created_by = auth.uid()::uuid);

ALTER TABLE public.test_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "test_plans_select" ON public.test_plans FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "test_plans_insert" ON public.test_plans FOR INSERT USING (auth.role() = 'authenticated') WITH CHECK (true);
CREATE POLICY "test_plans_manage" ON public.test_plans FOR UPDATE, DELETE USING (public.is_admin() OR created_by = auth.uid()::uuid);

ALTER TABLE public.test_plan_cases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "test_plan_cases_manage" ON public.test_plan_cases FOR ALL USING (public.is_admin() OR EXISTS (SELECT 1 FROM public.test_plans tp WHERE tp.id = plan_id AND tp.created_by = auth.uid()::uuid));

ALTER TABLE public.test_executions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "test_executions_select" ON public.test_executions FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "test_executions_insert" ON public.test_executions FOR INSERT USING (auth.role() = 'authenticated') WITH CHECK (true);
CREATE POLICY "test_executions_manage" ON public.test_executions FOR UPDATE, DELETE USING (public.is_admin() OR executed_by = auth.uid()::uuid);

ALTER TABLE public.bugs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "bugs_select" ON public.bugs FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "bugs_insert" ON public.bugs FOR INSERT USING (auth.role() = 'authenticated') WITH CHECK (true);
CREATE POLICY "bugs_manage" ON public.bugs FOR UPDATE, DELETE USING (public.is_admin() OR reported_by = auth.uid()::uuid OR assigned_to = auth.uid()::uuid);

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "activities_write" ON public.activities FOR INSERT USING (auth.role() = 'authenticated') WITH CHECK (true);
CREATE POLICY "activities_select_admin" ON public.activities FOR SELECT USING (public.is_admin());

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_self" ON public.profiles FOR SELECT USING (auth.uid()::uuid = id OR public.is_admin());
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT USING (auth.uid() IS NOT NULL) WITH CHECK (id = auth.uid()::uuid);
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (auth.uid()::uuid = id OR public.is_admin()) WITH CHECK (id = auth.uid()::uuid OR public.is_admin());

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_roles_admin_only" ON public.user_roles FOR ALL USING (public.is_admin());

-- Create some indexes
CREATE INDEX IF NOT EXISTS idx_test_cases_suite_id ON public.test_cases (suite_id);
CREATE INDEX IF NOT EXISTS idx_test_executions_plan_id ON public.test_executions (plan_id);
CREATE INDEX IF NOT EXISTS idx_bugs_status ON public.bugs (status);

-- End of init.sql
