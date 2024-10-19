FROM golang:1.17

WORKDIR /go/src/app

COPY *.go .

RUN go mod init dispatch && go get
RUN go install
RUN go mod tidy


CMD dispatch





