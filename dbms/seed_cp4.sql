BEGIN;

CREATE TEMP TABLE seed_users (
  n INTEGER PRIMARY KEY,
  id UUID NOT NULL
);

INSERT INTO seed_users
SELECT n, gen_random_uuid()
FROM generate_series(1, 1000) AS gs(n);

INSERT INTO "User" ("id", "name", "email", "passwordHash", "role", "createdAt", "updatedAt")
SELECT
  su.id,
  'CP4 User ' || su.n,
  'cp4_user_' || su.n || '@example.com',
  'benchmark_hash_placeholder',
  CASE WHEN su.n <= 200 THEN 'ORGANIZER'::"Role" ELSE 'ATTENDEE'::"Role" END,
  NOW() - (su.n || ' days')::interval,
  NOW()
FROM seed_users su;

CREATE TEMP TABLE seed_events (
  n INTEGER PRIMARY KEY,
  id UUID NOT NULL,
  organizer_id UUID NOT NULL
);

INSERT INTO seed_events
SELECT
  gs.n,
  gen_random_uuid(),
  su.id
FROM generate_series(1, 200) AS gs(n)
JOIN seed_users su ON su.n = ((gs.n - 1) % 200) + 1;

INSERT INTO "Event" (
  "id", "organizerId", "title", "description", "category",
  "venue", "address", "city", "timezone",
  "startAt", "endAt", "registrationClosesAt",
  "capacity", "priceMinor", "currency", "status",
  "createdAt", "updatedAt"
)
SELECT
  se.id,
  se.organizer_id,
  'CP4 Benchmark Event ' || se.n,
  'Seeded event for query performance benchmarking.',
  CASE se.n % 4
    WHEN 0 THEN 'Technology'
    WHEN 1 THEN 'Music'
    WHEN 2 THEN 'Education'
    ELSE 'Sports'
  END,
  'Benchmark Venue ' || se.n,
  'Benchmark Address ' || se.n,
  CASE se.n % 5
    WHEN 0 THEN 'Delhi'
    WHEN 1 THEN 'Mumbai'
    WHEN 2 THEN 'Bengaluru'
    WHEN 3 THEN 'Pune'
    ELSE 'Hyderabad'
  END,
  'Asia/Kolkata',
  NOW() + (se.n || ' days')::interval,
  NOW() + (se.n || ' days')::interval + INTERVAL '3 hours',
  NOW() + (se.n || ' days')::interval - INTERVAL '1 day',
  100 + se.n,
  se.n * 100,
  'INR',
  'PUBLISHED'::"EventStatus",
  NOW() - INTERVAL '30 days',
  NOW()
FROM seed_events se;

CREATE TEMP TABLE seed_bookings (
  n INTEGER PRIMARY KEY,
  id UUID NOT NULL,
  user_id UUID NOT NULL,
  event_id UUID NOT NULL
);

INSERT INTO seed_bookings
SELECT
  gs.n,
  gen_random_uuid(),
  su.id,
  se.id
FROM generate_series(1, 4000) AS gs(n)
JOIN seed_users su ON su.n = 201 + ((gs.n - 1) % 800)
JOIN seed_events se ON se.n = 1 + ((gs.n - 1) % 200);

INSERT INTO "Booking" (
  "id", "userId", "eventId", "status",
  "amountMinor", "currency", "eventSnapshot",
  "ticketCode", "createdAt", "updatedAt"
)
SELECT
  b.id,
  b.user_id,
  b.event_id,
  CASE b.n % 5
    WHEN 0 THEN CASE WHEN b.n <= 800 THEN 'PENDING_PAYMENT'::"BookingStatus" ELSE 'CANCELLED'::"BookingStatus" END
    WHEN 1 THEN 'CANCELLED'::"BookingStatus"
    WHEN 2 THEN 'EXPIRED'::"BookingStatus"
    ELSE CASE WHEN b.n <= 800 THEN 'CONFIRMED'::"BookingStatus" ELSE 'CANCELLED'::"BookingStatus" END
  END,
  5000,
  'INR',
  '{}'::jsonb,
  'CP4-TICKET-' || b.n,
  NOW() - (b.n || ' minutes')::interval,
  NOW()
FROM seed_bookings b;

INSERT INTO "Payment" (
  "id", "bookingId", "provider", "status",
  "amountMinor", "currency", "createdAt", "updatedAt"
)
SELECT
  gen_random_uuid(),
  b.id,
  'CP4',
  CASE b.n % 4
    WHEN 0 THEN 'OPEN'::"PaymentStatus"
    WHEN 1 THEN 'EXPIRED'::"PaymentStatus"
    ELSE 'PAID'::"PaymentStatus"
  END,
  5000,
  'INR',
  NOW() - (b.n || ' minutes')::interval,
  NOW()
FROM seed_bookings b
WHERE b.n % 4 <> 0;

COMMIT;

ANALYZE "User";
ANALYZE "Event";
ANALYZE "Booking";
ANALYZE "Payment";
