package platform

import (
	"bytes"
	"context"
	"net"
	"net/http"
)

type RealHttpClient struct {
	client *http.Client
}

func NewHttpClient() *RealHttpClient {
	return &RealHttpClient{
		client: &http.Client{
			Transport: &http.Transport{
				DialContext: func(_ context.Context, _, _ string) (net.Conn, error) {
					return net.Dial("unix", "/var/snap/platform/common/api.socket")
				},
			},
		},
	}
}

func (c *RealHttpClient) Post(url, contentType string, body []byte) (resp *http.Response, err error) {
	return c.client.Post(url, contentType, bytes.NewBuffer(body))
}
