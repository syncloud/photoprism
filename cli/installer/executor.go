package installer

import (
	"go.uber.org/zap"
	"os/exec"
	"strings"
)

type Executor struct {
	logger *zap.Logger
}

func NewExecutor(logger *zap.Logger) *Executor {
	return &Executor{
		logger: logger,
	}
}

func (e *Executor) Run(app string, args ...string) error {
	return e.run(exec.Command(app, args...))
}

func (e *Executor) RunAs(username string, app string, args ...string) error {
	sudoArgs := append([]string{"-H", "-u", username, app}, args...)
	return e.run(exec.Command("/usr/bin/sudo", sudoArgs...))
}

func (e *Executor) run(cmd *exec.Cmd) error {
	e.logger.Info("executing", zap.String("cmd", cmd.String()))
	out, err := cmd.CombinedOutput()
	e.logger.Info("command output")
	for _, line := range strings.Split(string(out), "\n") {
		e.logger.Info(line)
	}
	return err
}
