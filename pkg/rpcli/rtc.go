package rpcli

import (
	"github.com/mag1666888-del/protocol/rtc"
	"google.golang.org/grpc"
)

func NewRtcServiceClient(cc grpc.ClientConnInterface) *RtcServiceClient {
	return &RtcServiceClient{rtc.NewRtcServiceClient(cc)}
}

type RtcServiceClient struct {
	rtc.RtcServiceClient
}
