FROM rust:1.88-bookworm AS builder

WORKDIR /workspace/server
COPY . ./
RUN cargo build --release --locked && strip target/release/twende-server

FROM gcr.io/distroless/cc-debian12:nonroot

COPY --from=builder /workspace/server/target/release/twende-server /usr/local/bin/twende-server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

USER nonroot:nonroot
EXPOSE 8090
ENV RUST_LOG=info
ENTRYPOINT ["/usr/local/bin/twende-server"]
