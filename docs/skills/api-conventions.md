# API conventions

All public API endpoints are versioned under `/api/v1/`. Resources use plural nouns and path parameters use UUIDs: `/api/v1/listings/{id}`. Action endpoints are reserved for state transitions that are not ordinary updates, such as `/bookings/{id}/cancel`.

Authenticated requests send `Authorization: Bearer <access-token>`. A paginated list response uses `items`, `page`, `page_size`, and `total`; unpaginated endpoints should not imitate pagination fields.

Errors use a stable envelope:

```json
{
  "error": {
    "code": "validation_error",
    "message": "A human-readable explanation",
    "details": {}
  }
}
```

The OpenAPI document is the source of truth. A breaking public change requires a new path version (`/api/v2/`); non-breaking additions remain in the current version.
