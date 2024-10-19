# FROM golang:1.17

# WORKDIR /go/src/app

# COPY *.go .

# RUN go mod init dispatch && go get
# RUN go install

# CMD dispatch

# Use Go 1.18 (or later to avoid issues with some libraries)
FROM golang:1.18

WORKDIR /go/src/app

# Copy the Go source code
COPY *.go .

# Initialize the Go module (if not already initialized)
RUN go mod init dispatch

# Replace deprecated AMQP module with the new one
RUN go mod edit -replace=github.com/streadway/amqp=github.com/rabbitmq/amqp091-go@v1.6.0

# Download dependencies and update go.mod/go.sum files
RUN go mod tidy

# Build the Go application
RUN go build -o app .

# Set command to run the application
CMD ["./app"]



