# ADR 0001: Swiss Ephemeris integration

## Context

Jyotish Pro requires deterministic planetary positions and houses. Swiss
Ephemeris is a stateful C library and is not safe to call concurrently. It is
also dual-licensed under the AGPL and a commercial professional licence.

## Decision

Vendor the official Swiss Ephemeris 2.10.03 C runtime at upstream commit
`9083a12d59e98034fb2337061481ac8800c16e64` in a private `CSwissEph` package
target. Expose it only through the `EphemerisKit` protocol and the singleton
`SwissEphemeris` actor. The actor detects and rejects an unintended fallback
from requested Swiss data files to the Moshier implementation.

Ephemeris data files are configured at runtime and are not included in this
change. Moshier calculations remain available explicitly for tests and for
dates where its supported range and precision are acceptable.

## Alternatives considered

- A third-party Swift wrapper was rejected because it adds another dependency
  and weakens control over concurrency and numerical settings.
- Calling the C API from services was rejected because it would allow unsafe
  concurrent access and violate the dependency direction.
- Creating multiple wrapper actors was rejected because the C globals are
  shared across actor instances.

## Consequences

- All C access is serialized and Swift callers depend on a Sendable protocol.
- Production Swiss calculations fail clearly until licensed ephemeris data is
  bundled and its resource path configured.
- Before distributing a closed-source build, the owner must obtain the Swiss
  Ephemeris Professional licence. Otherwise the entire application must comply
  with AGPLv3.
