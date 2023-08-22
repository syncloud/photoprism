package log

import (
	"fmt"
	"go.uber.org/zap"
)

func Logger() *zap.Logger {
	logConfig := zap.NewProductionConfig()
	logConfig.Encoding = "console"
	logConfig.EncoderConfig.TimeKey = ""
	logConfig.EncoderConfig.ConsoleSeparator = " "
	logger, err := logConfig.Build()
	if err != nil {
		panic(fmt.Sprintf("can't initialize zap logger: %v", err))
	}
	return logger
}
