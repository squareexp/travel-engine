-- 016: Operator Profile Extended Fields

ALTER TABLE operator_profiles
    -- Location
    ADD COLUMN country                  TEXT,
    ADD COLUMN city                     TEXT,
    ADD COLUMN region                   TEXT,
    ADD COLUMN latitude                 NUMERIC(10, 7),
    ADD COLUMN longitude                NUMERIC(10, 7),

    -- Branding
    ADD COLUMN logo_url                 TEXT,

    -- Fleet
    ADD COLUMN fleet_size               INT,
    ADD COLUMN fleet_types              TEXT[],

    -- Social presence
    ADD COLUMN facebook_url             TEXT,
    ADD COLUMN instagram_url            TEXT,
    ADD COLUMN whatsapp_number          TEXT,

    -- Operations
    ADD COLUMN languages                TEXT[],
    ADD COLUMN years_in_operation       INT,
    ADD COLUMN business_email           TEXT,

    -- Payout info
    ADD COLUMN mpesa_number             TEXT,
    ADD COLUMN bank_account_number      TEXT,
    ADD COLUMN bank_name                TEXT,

    -- Emergency contact
    ADD COLUMN emergency_contact_name   TEXT,
    ADD COLUMN emergency_contact_phone  TEXT,

    -- Documents (GCS URLs)
    ADD COLUMN insurance_document_url   TEXT;
