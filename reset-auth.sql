-- This SQL script resets auth settings to work with the iOS app

-- Enable insecure HTTP for development (use HTTPS in production)
UPDATE auth.config
SET redirect_urls = ARRAY['com.hitrivals.app://login-callback'],
    site_url = 'https://localhost:3000',
    email_confirmations = FALSE,
    double_confirm_email_changes = FALSE,
    enable_signup = TRUE;

-- Reset any login errors in the audit log
DELETE FROM auth.audit_log_entries 
WHERE activity = 'login' AND error IS NOT NULL;

-- Clear any failed login attempts
DELETE FROM auth.users_failed_attempts;

-- Output success message
SELECT 'Auth settings updated successfully' as message; 