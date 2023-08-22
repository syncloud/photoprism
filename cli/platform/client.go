package platform

import (
	"encoding/json"
	"fmt"
	"go.uber.org/zap"
	"hooks/log"
	"io"
	"net/http"
	"net/url"
)

type HttpClient interface {
	Post(url string, values url.Values) (resp *http.Response, err error)
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
	values := url.Values{"app_name": {app}, "user_name": {user}}
	c.logger.Info("init storage", zap.String("request", values.Encode()))
	resp, err := c.client.Post("http://unix/app/init_storage", values)
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
