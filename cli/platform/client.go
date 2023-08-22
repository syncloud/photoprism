package platform

import (
	"encoding/json"
	"fmt"
	"go.uber.org/zap"
	"hooks/log"
	"io"
	"net/http"
)

type HttpClient interface {
	Post(url, contentType string, body []byte) (resp *http.Response, err error)
}

type Client struct {
	client HttpClient
	logger *zap.Logger
}

func New() *Client {
	return &Client{
		client: NewHttpClient(),
		logger: log.Logger(),
	}
}

func (c *Client) InitStorage(app, user string) (string, error) {
	requestJson, err := json.Marshal(InitStorageRequest{AppName: app, UserName: user})
	if err != nil {
		return "", err
	}
	c.logger.Info("init storage", zap.String("request", string(requestJson)))
	resp, err := c.client.Post("http://unix/app/init_storage", "application/json", requestJson)
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
