# FROM golang:1.17

# WORKDIR /go/src/app

# COPY *.go .

# RUN go mod init dispatch && go get
# RUN go install

# CMD dispatch

# Use Go 1.18 (or later)
FROM golang:1.18

WORKDIR /go/src/app

# Copy all .go files
COPY *.go .

# Initialize the module and download dependencies
RUN go mod init dispatch && go mod tidy

# Replace deprecated module
RUN go mod edit -replace=github.com/streadway/amqp=github.com/rabbitmq/amqp091-go@v1.0.0

# Download dependencies to ensure go.sum is updated
RUN go mod download

# Build the Go application
RUN go build -o app .

# Command to run the app
CMD ["./app"]
