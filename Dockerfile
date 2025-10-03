# builder
FROM golang:1.22-alpine AS builder
WORKDIR /app
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
ENV GONOPROXY=github.com/mag1666888-del/* GONOSUMDB=github.com/mag1666888-del/* GOPRIVATE=github.com/mag1666888-del/*
RUN apk add --no-cache git
COPY go.mod go.sum ./
RUN git config --global url."https://github.com/mag1666888-del/".insteadOf "git@github.com:mag1666888-del/"
RUN git clone https://github.com/mag1666888-del/protocol.git /protocol
RUN go mod download
ARG TARGET=./cmd/openim-api
ARG BIN_NAME=openim-api
COPY . .
# 根据 TARGET 参数构建指定组件二进制
RUN go build -o /out/${BIN_NAME} ${TARGET}

# runtime
FROM alpine:3.19
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
ARG BIN_NAME=openim-api
COPY --from=builder /out/${BIN_NAME} /app/app
COPY --from=builder /app/config /config
COPY --from=builder /app/start-config.yml /config/start-config.yml
EXPOSE 10001
ENTRYPOINT ["/app/app", "-c", "/config"]
