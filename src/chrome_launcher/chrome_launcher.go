package main

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
)

// Endianness represents native endianness (hardcoded for amd64 for now).
var Endianness = binary.LittleEndian

// Message represent messages received from Chrome
type Message struct {
	URL string `json:"url"`
}

func main() {
	for msg := range MessagesFrom(os.Stdin) {
		command := fmt.Sprintf("nohup mpv --ytdl %s >/dev/null 2>&1", msg.URL)
		go exec.Command("sh", "-c", command).Run()
	}
}

// MessagesFrom reads messages from provided io.Reader argument.
func MessagesFrom(stream io.Reader) <-chan Message {
	msgs := make(chan Message)

	go func(sink chan<- Message) {
		for {
			sink <- ReadMessageFrom(stream)
		}
	}(msgs)

	return msgs
}

// ReadMessageFrom returns Message object it read from stream.
func ReadMessageFrom(stream io.Reader) Message {
	rawMsg, err := ReadRawMessageFrom(stream)

	if err != nil {
		log.Fatal(err)
	}

	m, err := DecodeMessage(rawMsg)

	if err != nil {
		log.Fatal(err)
	}

	return m
}

// WriteMessageTo serializes Message object and sends it to stream.
func WriteMessageTo(stream io.Writer, msg Message) {
	rawMsg, err := EncodeMessage(msg)

	if err != nil {
		log.Fatal(err)
	}

	if err := SendRawMessageTo(stream, rawMsg); err != nil {
		log.Fatal(err)
	}
}

// ReadRawMessageFrom reads a single message from provided  source.
func ReadRawMessageFrom(stream io.Reader) ([]byte, error) {
	rawMsgLen := make([]byte, 4)

	if len, err := stream.Read(rawMsgLen); err != nil {
		return []byte{}, err
	} else if len != 4 {
		return []byte{}, fmt.Errorf("Failed to read message length")
	}

	var msgLen int32

	if err := binary.Read(bytes.NewReader(rawMsgLen), Endianness, &msgLen); err != nil {
		return []byte{}, err
	}

	msg := make([]byte, msgLen)

	if observedMsgLen, err := stream.Read(msg); err != nil {
		return []byte{}, err
	} else if observedMsgLen != int(msgLen) {
		return []byte{}, fmt.Errorf("failed to read message properly")
	}

	return msg, nil
}

// SendRawMessageTo sends given message to a given stream.
func SendRawMessageTo(stream io.Writer, msg []byte) error {
	msgLen := int32(len(msg))
	var rawMsgLen bytes.Buffer

	if err := binary.Write(&rawMsgLen, Endianness, msgLen); err != nil {
		return err
	}

	if len, err := stream.Write(rawMsgLen.Bytes()); err != nil {
		return err
	} else if len != 4 {
		return fmt.Errorf("failed to send message length")
	}

	if len, err := stream.Write(msg); err != nil {
		return err
	} else if len != int(msgLen) {
		return fmt.Errorf("failed to send a message")
	}

	return nil
}

// DecodeMessage makes Message object form its JSON representation.
func DecodeMessage(rawMsg []byte) (Message, error) {
	var m Message

	decoder := json.NewDecoder(bytes.NewBuffer(rawMsg))

	err := decoder.Decode(&m)
	return m, err
}

// EncodeMessage serializes Message object into byte slice.
func EncodeMessage(msg Message) ([]byte, error) {
	var rawMsg bytes.Buffer

	encoder := json.NewEncoder(&rawMsg)

	err := encoder.Encode(msg)
	return rawMsg.Bytes(), err
}
