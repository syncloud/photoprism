package platform

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
)

type HttpClient struct {
	client *http.Client
}

func New() *HttpClient {
	return &HttpClient{
		client: &http.Client{
			Transport: &http.Transport{
				DialContext: func(_ context.Context, _, _ string) (net.Conn, error) {
					return net.Dial("unix", "/var/snap/platform/common/api.socket")
				},
			},
		},
	}
}

func (c *HttpClient) InitStorage(app, user string) (string, error) {
	requestJson, err := json.Marshal(InitStorageRequest{AppName: app, UserName: user})
	if err != nil {
		return "", err
	}
	resp, err := c.client.Post("http://unix/app/init_storage", "application/json", bytes.NewBuffer(requestJson))
	if err != nil {
		return "", err
	}
	if resp.StatusCode != 200 {
		return "", fmt.Errorf("unable to init storage, %s", resp.Status)
	}
	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	var responseJson InitStorageResponse
	err = json.Unmarshal(bodyBytes, &responseJson)
	if err != nil {
		return "", err
	}
	return responseJson.Data, nil
}

