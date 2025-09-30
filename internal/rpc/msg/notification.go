// Copyright © 2024 my-open-im. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package msg

import (
	"context"

	"github.com/mag1666888-del/my-open-im-server/v3/pkg/notification"
	"github.com/mag1666888-del/protocol/constant"
	"github.com/mag1666888-del/protocol/sdkws"
)

type MsgNotificationSender struct {
	*notification.NotificationSender
}

func NewMsgNotificationSender(config *Config, opts ...notification.NotificationSenderOptions) *MsgNotificationSender {
	return &MsgNotificationSender{notification.NewNotificationSender(&config.NotificationConfig, opts...)}
}

func (m *MsgNotificationSender) UserDeleteMsgsNotification(ctx context.Context, userID, conversationID string, seqs []int64) {
	tips := sdkws.DeleteMsgsTips{
		UserID:         userID,
		ConversationID: conversationID,
		Seqs:           seqs,
	}
	m.Notification(ctx, userID, userID, constant.DeleteMsgsNotification, &tips)
}

func (m *MsgNotificationSender) MarkAsReadNotification(ctx context.Context, conversationID string, sessionType int32, sendID, recvID string, seqs []int64, hasReadSeq int64) {
	tips := &sdkws.MarkAsReadTips{
		MarkAsReadUserID: sendID,
		ConversationID:   conversationID,
		Seqs:             seqs,
		HasReadSeq:       hasReadSeq,
	}
	m.NotificationWithSessionType(ctx, sendID, recvID, constant.HasReadReceipt, sessionType, tips)
}
