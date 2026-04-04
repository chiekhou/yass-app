-- ============================================================
-- Demo accounts for Apple App Review & developer access
-- Run this script once against the production/staging database
-- via DBVisualizer or psql
--
-- Accounts created:
--   Admin (developer): chiekhou@yass.dz          / Admin@123456
--   Demo user:         demo.user@yass.dz          / User@123456
--   Demo partner:      demo.partner@yass.dz       / Partner@123456
-- ============================================================

-- 1. Admin account for the developer (chiekhou)
INSERT INTO users (
  id, email, password, first_name, last_name,
  role, status, email_verified, created_at, updated_at
)
SELECT
  'a0000000-0000-0000-0000-000000000001',
  'chiekhou@yass.dz',
  '$2b$12$buxj1iRIjSz8l137UYGbkueZXWyY73oJ8MOKKuBPqsxdk3mXYwQRC',
  'Chiekhou',
  'Admin',
  'admin',
  'active',
  TRUE,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE email = 'chiekhou@yass.dz'
);

-- 2. Demo regular user (Apple App Review)
INSERT INTO users (
  id, email, password, first_name, last_name,
  role, status, email_verified, created_at, updated_at
)
SELECT
  'a0000000-0000-0000-0000-000000000002',
  'demo.user@yass.dz',
  '$2b$12$6ElbWhz7PITi.zD/4SYS0.6PbPw0XPYOqIkyGxmyJy2b/sUkotAZS',
  'Demo',
  'User',
  'user',
  'active',
  TRUE,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE email = 'demo.user@yass.dz'
);

-- 3. Demo partner user (Apple App Review)
INSERT INTO users (
  id, email, password, first_name, last_name,
  role, status, email_verified, created_at, updated_at
)
SELECT
  'a0000000-0000-0000-0000-000000000003',
  'demo.partner@yass.dz',
  '$2b$12$9pyZIKhMr5jxKY6Nbml6o.dwx.6OpReLOM3EXvcjHV5XaF5vsyIGK',
  'Demo',
  'Partner',
  'partner',
  'active',
  TRUE,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE email = 'demo.partner@yass.dz'
);

-- 4. Partner record for demo partner (approved, premium plan)
INSERT INTO partners (
  id, user_id, company_name, status,
  subscription_plan,
  created_at, updated_at
)
SELECT
  'a0000000-0000-0000-0001-000000000003',
  'a0000000-0000-0000-0000-000000000003',
  'Demo Business',
  'approved',
  'premium',
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM partners WHERE user_id = 'a0000000-0000-0000-0000-000000000003'
);
