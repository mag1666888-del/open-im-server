# Use Go 1.22 Alpine as the base image for building the application
FROM golang:1.22-alpine AS builder

# Define the base directory for the application as an environment variable
ENV SERVER_DIR=/openim-server

# Set the working directory inside the container based on the environment variable
WORKDIR $SERVER_DIR

# Set the Go proxy to improve dependency resolution speed
# ENV GOPROXY=https://goproxy.io,direct

# Configure Go environment for private repositories
ENV GONOPROXY=github.com/mag1666888-del/*
ENV GONOSUMDB=github.com/mag1666888-del/*
ENV GOPRIVATE=github.com/mag1666888-del/*

# Install Git for cloning private repositories
RUN apk add --no-cache git

# Copy go.mod and go.sum first
COPY go.mod go.sum ./

# Configure Git for private repositories
RUN git config --global url."https://github.com/mag1666888-del/".insteadOf "git@github.com:mag1666888-del/"

# Clone the protocol dependency from Git
RUN git clone https://github.com/mag1666888-del/protocol.git /protocol

RUN go mod download

# Copy all files from the current directory into the container
COPY . .

# Install Mage to use for building the application
RUN go install github.com/magefile/mage@v1.15.0

# Optionally build your application if needed
RUN mage build

# Using Alpine Linux with Go environment for the final image
FROM golang:1.22-alpine

# Install necessary packages, such as bash and git
RUN apk add --no-cache bash git

# Configure Go environment for private repositories
ENV GONOPROXY=github.com/mag1666888-del/*
ENV GONOSUMDB=github.com/mag1666888-del/*
ENV GOPRIVATE=github.com/mag1666888-del/*

# Set the environment and work directory
ENV SERVER_DIR=/openim-server
WORKDIR $SERVER_DIR

# Configure Git for private repositories
RUN git config --global url."https://github.com/mag1666888-del/".insteadOf "git@github.com:mag1666888-del/"

# Clone the protocol dependency from Git
RUN git clone https://github.com/mag1666888-del/protocol.git /protocol


# Copy the compiled binaries and mage from the builder image to the final image
COPY --from=builder $SERVER_DIR/_output $SERVER_DIR/_output
COPY --from=builder $SERVER_DIR/config $SERVER_DIR/config
COPY --from=builder /go/bin/mage /usr/local/bin/mage
COPY --from=builder $SERVER_DIR/magefile_windows.go $SERVER_DIR/
COPY --from=builder $SERVER_DIR/magefile_unix.go $SERVER_DIR/
COPY --from=builder $SERVER_DIR/magefile.go $SERVER_DIR/
COPY --from=builder $SERVER_DIR/start-config.yml $SERVER_DIR/
COPY --from=builder $SERVER_DIR/go.mod $SERVER_DIR/
COPY --from=builder $SERVER_DIR/go.sum $SERVER_DIR/

RUN go get github.com/openimsdk/gomake@v0.0.15-alpha.1

# Set the command to run when the container starts
ENTRYPOINT ["sh", "-c", "mage start && tail -f /dev/null"]
