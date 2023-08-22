package platform

import (
	"context"
	"net"
	"net/http"
	"net/url"
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

func (c *RealHttpClient) Post(url string, values url.Values) (resp *http.Response, err error) {
	return c.client.PostForm(url, values)
}
