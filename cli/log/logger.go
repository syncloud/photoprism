package log

import (
	"fmt"
	zapsyslog "github.com/richiefi/zap-syslog"
	"github.com/richiefi/zap-syslog/syslog"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"os"
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

func SysLogger(app string) *zap.Logger {
	enc := zapsyslog.NewSyslogEncoder(zapsyslog.SyslogEncoderConfig{
		EncoderConfig: zapcore.EncoderConfig{
			NameKey:        "logger",
			CallerKey:      "caller",
			MessageKey:     "msg",
			StacktraceKey:  "stacktrace",
			EncodeLevel:    zapcore.LowercaseLevelEncoder,
			EncodeTime:     zapcore.EpochTimeEncoder,
			EncodeDuration: zapcore.SecondsDurationEncoder,
			EncodeCaller:   zapcore.ShortCallerEncoder,
		},

		Facility: syslog.LOG_LOCAL0,
		Hostname: "",
		PID:      os.Getpid(),
		App:      app,
	})

	sink, err := zapsyslog.NewConnSyncer("unixgram", "/dev/log")
	if err != nil {
		panic(err)
	}

	atom := zap.NewAtomicLevel()
	logger := zap.New(zapcore.NewCore(
		enc,
		zapcore.Lock(sink),
		atom,
	))
	return logger
}
