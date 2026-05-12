package installer

import (
	"fmt"
	"go.uber.org/zap"
	"os/exec"
	"os/user"
	"strconv"
	"strings"
	"syscall"
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
	u, err := user.Lookup(username)
	if err != nil {
		return fmt.Errorf("lookup user %s: %w", username, err)
	}
	uid, err := strconv.Atoi(u.Uid)
	if err != nil {
		return fmt.Errorf("parse uid for %s: %w", username, err)
	}
	gid, err := strconv.Atoi(u.Gid)
	if err != nil {
		return fmt.Errorf("parse gid for %s: %w", username, err)
	}
	cmd := exec.Command(app, args...)
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Credential: &syscall.Credential{Uid: uint32(uid), Gid: uint32(gid)},
	}
	return e.run(cmd)
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
