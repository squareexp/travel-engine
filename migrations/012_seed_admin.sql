-- Promote test admin user to admin role (dev seed only)
UPDATE users SET role = 'admin' WHERE email = 'admin@test.com';
