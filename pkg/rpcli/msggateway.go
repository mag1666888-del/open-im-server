package rpcli

import (
	"github.com/mag1666888-del/protocol/msggateway"
	"google.golang.org/grpc"
)

func NewMsgGatewayClient(cc grpc.ClientConnInterface) *MsgGatewayClient {
	return &MsgGatewayClient{msggateway.NewMsgGatewayClient(cc)}
}

type MsgGatewayClient struct {
	msggateway.MsgGatewayClient
}
