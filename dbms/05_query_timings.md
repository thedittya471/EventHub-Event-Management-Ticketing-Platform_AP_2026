# CP4 - Query Performance Analysis

## Environment
- Database: PostgreSQL
- Database name: eventhub_cp4
- Dataset: 1000 Users, 200 Events, 4000 Bookings, 3000 Payments
- Analysis method: EXPLAIN (ANALYZE, BUFFERS)

## Query Performance Results

| Query | Description | Execution Time | Buffers |
|---|---|---:|---:|
| Q1 | Public events listing with organizer join | 0.238 ms | 74 |
| Q2 | Active booking count grouped by event | 0.796 ms | 14 |
| Q3 | User booking history | 0.499 ms | 21 |
| Q4 | Organizer event listing | 0.054 ms | 4 |
| Q5 | Attendee search | 0.143 ms | 6 |

## Query Plan Observations

### Q1 - Public Events
- Used Event_status_startAt_idx.
- User primary key index used for organizer lookup.
- Incremental Sort was used.
- Execution time: 0.238 ms.

### Q2 - Booking Counts
- Hash Join and HashAggregate used.
- Booking_one_active_per_user_event index-only scan used.
- Heap Fetches: 0.
- 480 matching bookings grouped into 120 event groups.
- Execution time: 0.796 ms.

### Q3 - User Booking History
- Booking_userId_createdAt_idx used.
- Bitmap Index Scan and Bitmap Heap Scan observed.
- Hash Join used for event details.
- Execution time: 0.499 ms.

### Q4 - Organizer Events
- Event_organizerId_createdAt_idx used.
- Index Scan Backward used for descending createdAt ordering.
- Execution time: 0.054 ms.

### Q5 - Attendee Search
- Booking_eventId_status_idx used.
- Bitmap Index Scan and Bitmap Heap Scan observed.
- Nested Loop join planned.
- No matching rows were returned for the selected event and search condition in this run.
- Execution time: 0.143 ms.

## Index Analysis

Existing indexes supported the tested access patterns:

- Public event filtering by status and startAt.
- Active booking lookup and grouping.
- User booking history lookup.
- Organizer event listing sorted by createdAt.
- Event attendee filtering by eventId and status.

The observed execution plans used relevant existing indexes for these queries. Based on these test runs, no additional index was immediately justified.

## Conclusion

The five representative queries were tested using EXPLAIN ANALYZE and BUFFERS on the seeded database.

The observed execution times were low in this local test environment. Existing indexes were used in the tested query plans where appropriate.

These timings represent individual test runs and should not be treated as a benchmark under production load. Further testing with larger datasets and repeated measurements would provide a more reliable comparison.
