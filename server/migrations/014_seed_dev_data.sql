-- 014: Seed bulk dev data (~5000 listings + availability + extensions).
--
-- Safe to re-run: each section guards against duplicates by checking row counts
-- or using ON CONFLICT.

-- 1. Ensure we have ~20 destinations (8 seed already exist + 12 more).
INSERT INTO destinations (name, country, region, latitude, longitude, description)
SELECT v.name, 'Tanzania', v.region, v.lat, v.lng, v.descr
  FROM (VALUES
    ('Jambiani Beach', 'Zanzibar', -6.3083, 39.5467, 'Quiet seaweed-farming village beach on the south-east coast'),
    ('Matemwe Beach', 'Zanzibar', -5.8736, 39.3500, 'Long sandy beach facing Mnemba Atoll'),
    ('Prison Island', 'Zanzibar', -6.1330, 39.1750, 'Historic island home to giant Aldabra tortoises'),
    ('Mafia Island', 'Pwani', -7.9000, 39.7333, 'Marine park with whale-shark season Oct–Mar'),
    ('Mnemba Atoll', 'Zanzibar', -5.8133, 39.3833, 'World-class snorkeling and diving site'),
    ('Tarangire', 'Manyara', -3.8333, 36.0000, 'Park famous for huge elephant herds and baobabs'),
    ('Lake Manyara', 'Manyara', -3.5000, 35.8167, 'Rift Valley lake with tree-climbing lions'),
    ('Selous (Nyerere)', 'Pwani', -8.0000, 37.5000, 'Largest game reserve in Africa'),
    ('Ruaha', 'Iringa', -7.7000, 35.0000, 'Remote wilderness with lion and elephant'),
    ('Bagamoyo', 'Pwani', -6.4400, 38.9000, 'Historic Swahili coastal town and former capital'),
    ('Pemba Island', 'Pemba', -5.0000, 39.7000, 'Lush green island known for spice farms'),
    ('Arusha', 'Arusha', -3.3667, 36.6833, 'Gateway city to northern safari circuit')
  ) AS v(name, region, lat, lng, descr)
WHERE NOT EXISTS (SELECT 1 FROM destinations d WHERE d.name = v.name);

-- 2. Ensure we have a verified "Demo Operator" user that owns the seed data.
INSERT INTO users (id, email, full_name, role, is_verified, password_hash, idp_subject, idp_issuer)
SELECT
    '11111111-1111-1111-1111-111111111111'::uuid,
    'demo-operator@twende.local',
    'Twende Demo Operator',
    'operator'::user_role,
    TRUE,
    NULL,
    'demo-operator-seed',
    'http://localhost:8080'
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE id = '11111111-1111-1111-1111-111111111111'::uuid
);

INSERT INTO operator_profiles (user_id, business_name, business_description, verification_status, verified_at)
SELECT
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Twende Demo Tours',
    'Auto-generated dev operator for prototype seed data',
    'verified'::operator_verification_status,
    now()
ON CONFLICT (user_id) DO NOTHING;

-- 3. Bulk insert ~5000 listings spread across all types and destinations.
--    Only insert if we don't already have a lot of listings.
DO $$
DECLARE
    existing_count BIGINT;
    op_id UUID := '11111111-1111-1111-1111-111111111111'::uuid;
BEGIN
    SELECT COUNT(*) INTO existing_count FROM listings
        WHERE operator_id = op_id AND deleted_at IS NULL;

    IF existing_count >= 4900 THEN
        RAISE NOTICE 'Seed data already present (% listings) — skipping bulk insert', existing_count;
        RETURN;
    END IF;

    INSERT INTO listings (
        id, operator_id, destination_id, listing_type, title, description,
        base_price, currency, status, image_urls, tags
    )
    SELECT
        gen_random_uuid(),
        op_id,
        d.id,
        CASE n % 4
            WHEN 0 THEN 'site'::listing_type
            WHEN 1 THEN 'experience'::listing_type
            WHEN 2 THEN 'trip'::listing_type
            ELSE 'safari'::listing_type
        END,
        CASE n % 4
            WHEN 0 THEN d.name || ' Walking Tour #' || n
            WHEN 1 THEN d.name || ' Cultural Experience #' || n
            WHEN 2 THEN d.name || ' Day Trip #' || n
            ELSE d.name || ' Safari Adventure #' || n
        END,
        CASE n % 4
            WHEN 0 THEN 'Discover ' || d.name || ' with a local guide. Iconic landmarks, hidden alleys, and authentic Swahili stories.'
            WHEN 1 THEN 'Hands-on Zanzibari spice farm, cooking class, and dhow sail at sunset around ' || d.name || '.'
            WHEN 2 THEN 'Full-day exploration of ' || d.name || ' — snorkeling, beach lunch, and free time to relax.'
            ELSE 'Game drives at sunrise and sunset in ' || d.name || '. Big Five sightings and expert ranger guidance.'
        END,
        (40 + (n % 40) * 12 + (CASE WHEN n % 4 = 3 THEN 800 ELSE 0 END))::numeric(12,2),
        'USD',
        'active'::listing_status,
        ARRAY[
            CASE n % 4
                WHEN 0 THEN 'https://images.unsplash.com/photo-1580973193083-c2b8a37d6a6a?w=800'
                WHEN 1 THEN 'https://images.unsplash.com/photo-1571401835393-8c5f35328320?w=800'
                WHEN 2 THEN 'https://images.unsplash.com/photo-1591608971362-f08b2a75731a?w=800'
                ELSE      'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=800'
            END
        ],
        ARRAY['featured', d.region]
    FROM destinations d
    CROSS JOIN generate_series(1, 250) AS n
    WHERE d.is_active;
END $$;

-- 4. Class-table extension rows for each newly-seeded listing.
INSERT INTO site_details (listing_id, duration_hours, max_capacity, includes_transport, highlights)
SELECT id, 3.5, 15, FALSE,
       ARRAY['Local guide', 'Bottled water', 'Hotel pickup & drop-off']
  FROM listings
 WHERE listing_type = 'site'
   AND NOT EXISTS (SELECT 1 FROM site_details s WHERE s.listing_id = listings.id);

INSERT INTO experience_details (listing_id, theme, duration_hours, min_participants, max_participants)
SELECT id, 'Culture & Food', 4, 2, 10
  FROM listings
 WHERE listing_type = 'experience'
   AND NOT EXISTS (SELECT 1 FROM experience_details e WHERE e.listing_id = listings.id);

INSERT INTO trip_details (listing_id, duration_days, max_participants, difficulty_level)
SELECT id, 3, 8, 'easy'
  FROM listings
 WHERE listing_type = 'trip'
   AND NOT EXISTS (SELECT 1 FROM trip_details t WHERE t.listing_id = listings.id);

INSERT INTO safari_details (listing_id, park_name, vehicle_class, game_drive_window, park_fee_amount, park_fee_currency)
SELECT id,
       (SELECT name FROM destinations WHERE destinations.id = listings.destination_id),
       'shared_jeep',
       '06:00-10:00 & 15:30-18:30',
       80.00, 'USD'
  FROM listings
 WHERE listing_type = 'safari'
   AND NOT EXISTS (SELECT 1 FROM safari_details s WHERE s.listing_id = listings.id);

-- 5. Seed availability for the next 60 days on every active seeded listing.
INSERT INTO availability (listing_id, travel_date, capacity)
SELECT l.id, CURRENT_DATE + d, 12
  FROM listings l
  CROSS JOIN generate_series(1, 60) AS d
 WHERE l.operator_id = '11111111-1111-1111-1111-111111111111'::uuid
   AND l.deleted_at IS NULL
ON CONFLICT (listing_id, travel_date) DO NOTHING;
