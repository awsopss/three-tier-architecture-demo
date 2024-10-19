# FROM golang:1.17

# WORKDIR /go/src/app

# COPY *.go .

# RUN go mod init dispatch && go get
# RUN go install

# CMD dispatch

# Base Image for Dispatch Service
FROM golang:1.18

WORKDIR /go/src/dispatch

# Copy source code
COPY . .

# Build the Go dispatch service
RUN go mod tidy && go build -o dispatch .

# Expose the port for the service
EXPOSE 8080

# Run the dispatch service
CMD ["./dispatch"]
