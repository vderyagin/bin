package main

import (
	"bytes"
	"testing"
)

func TestExchangingMessages(t *testing.T) {
	var buf bytes.Buffer

	if err := SendRawMessageTo(&buf, []byte("foo")); err != nil {
		t.Error(err)
	}

	if msg, err := ReadRawMessageFrom(bytes.NewReader(buf.Bytes())); err != nil {
		t.Error("receiving message should have succeeded")
	} else if string(msg) != "foo" {
		t.Errorf("received wrong message: '%s'", string(msg))
	}
}

func TestDecodeMessageSuccess(t *testing.T) {
	if msg, err := DecodeMessage([]byte(`{"url": "foo"}`)); err != nil {
		t.Error(err)
	} else if msg.URL != "foo" {
		t.Error("did not decode message properly")
	}
}

func TestDecodeMessageFail(t *testing.T) {
	if _, err := DecodeMessage([]byte(`{"url" "foo"}`)); err == nil {
		t.Error("should fail to decode broken message")
	}
}

func TestEncodeMessageSuccess(t *testing.T) {
	if rawMsg, err := EncodeMessage(Message{URL: "foo"}); err != nil {
		t.Error(err)
	} else if string(rawMsg) != `{"url":"foo"}`+"\n" {
		t.Errorf("message is not encoded properly: '%s'", string(rawMsg))
	}
}
