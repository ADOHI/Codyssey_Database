CREATE INDEX idx_enrollment_enrolled_at ON enrollment (enrolled_at);

SHOW INDEX FROM enrollment WHERE Key_name = 'idx_enrollment_enrolled_at';
