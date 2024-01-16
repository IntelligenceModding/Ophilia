# Use an official Rust runtime as a parent image (Using ARG for versioning)
ARG RUST_VERSION=1.75.0
FROM rust:${RUST_VERSION}-slim-bullseye as builder

# Set up a new build environment and change the working directory in the docker image
WORKDIR /usr/app

# Create a new dummy Cargo.toml with just the dependencies
RUN echo "[package]\nname = \"dummy\"\nversion = \"0.1.0\"\nedition = \"2018\"\n\n# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html\n\n[dependencies]\n" > Cargo.toml

# Copy only Cargo.lock to make use of Docker cache, and install the dependencies
COPY Cargo.lock ./

RUN mkdir src \
    && echo "fn main() {println!(\"if you see this, the build broke\")}" > src/main.rs \
    && cargo build --release \
    && rm -rf src/ Cargo.lock Cargo.toml

# Now, copy the actual source code and build the application using the dependencies installed above
COPY . .
RUN cargo build --release

# Second stage, a thin image / runtime environment
FROM rust:${RUST_VERSION}-slim-bullseye
ARG APP=/usr/src/app
ARG ENTRYPOINT_BINARY="ophilia"
WORKDIR ${APP}

RUN apt-get update \
    && apt-get install -y ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

# Copies release binary from Builder to this new image
COPY --from=builder /usr/app/target/release/${ENTRYPOINT_BINARY} .
RUN chmod +x ./ophilia

USER 1000
ENTRYPOINT ["./ophilia"]