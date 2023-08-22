package platform

import (
	"bytes"
	"github.com/stretchr/testify/assert"
	"hooks/log"
	"io"
	"net/http"
	"net/url"
	"testing"
)

type HttpClientStub struct {
	values url.Values
}

func (h *HttpClientStub) Post(url string, values url.Values) (resp *http.Response, err error) {
	h.values = values
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
	assert.Contains(t, httpClient.values.Encode(), "app")
	assert.Contains(t, httpClient.values.Encode(), "user")
	assert.Equal(t, "/data/app", storage)

}
