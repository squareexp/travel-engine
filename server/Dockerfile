# Stage 1: Chef - for dependency caching
FROM rust:1.88-bookworm AS chef
RUN cargo install cargo-chef
WORKDIR /workspace/server

# Stage 2: Planner - generate recipe
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# Stage 3: Builder - build dependencies + application
FROM chef AS builder
COPY --from=planner /workspace/server/recipe.json recipe.json
# Build dependencies (cached)
RUN cargo chef cook --release --recipe-path recipe.json
# Build application (only recompiles when source changes)
COPY . .
RUN cargo build --release --locked && strip target/release/twende-server

# Stage 4: Runtime
FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=builder /workspace/server/target/release/twende-server /usr/local/bin/twende-server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
USER nonroot:nonroot
EXPOSE 8090
ENV RUST_LOG=info
ENTRYPOINT ["/usr/local/bin/twende-server"]
