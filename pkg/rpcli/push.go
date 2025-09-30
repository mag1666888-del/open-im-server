package rpcli

import (
	"github.com/mag1666888-del/protocol/push"
	"google.golang.org/grpc"
)

func NewPushMsgServiceClient(cc grpc.ClientConnInterface) *PushMsgServiceClient {
	return &PushMsgServiceClient{push.NewPushMsgServiceClient(cc)}
}

type PushMsgServiceClient struct {
	push.PushMsgServiceClient
}
