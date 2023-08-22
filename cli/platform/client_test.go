package platform

import (
	"bytes"
	"github.com/stretchr/testify/assert"
	"hooks/log"
	"io"
	"net/http"
	"testing"
)

type HttpClientStub struct {
	request string
}

func (h *HttpClientStub) Post(url, contentType string, body []byte) (resp *http.Response, err error) {
	h.request = string(body)
	return &http.Response{
		StatusCode: 200,
		Body: io.NopCloser(bytes.NewReader([]byte(`
{
	"success": true,
	"data": "/data/app"
}
`))),
	}, nil
}

func TestRealHttpClient_Post(t *testing.T) {
	httpClient := &HttpClientStub{}
	client := &Client{
		client: httpClient,
		logger: log.Logger(),
	}
	storage, err := client.InitStorage("app", "user")
	assert.NoError(t, err)
	assert.Equal(t, "/data/app", httpClient.request)
	assert.Equal(t, "/data/app", storage)

}