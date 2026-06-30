-- 018: Drop unused tourism_license_issuer/tourism_license_class columns
--
-- These were added in 017 but which license applies (TALA vs ZCT, Class A
-- vs C) is derived at read time from service_categories + location by
-- crate::compliance::tourism_license_label — no need to store it separately.

ALTER TABLE operator_profiles
    DROP COLUMN tourism_license_issuer,
    DROP COLUMN tourism_license_class;
