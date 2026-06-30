-- 015: Operator replies to reviews

ALTER TABLE reviews
    ADD COLUMN operator_reply TEXT,
    ADD COLUMN operator_replied_at TIMESTAMPTZ;
