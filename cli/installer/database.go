package installer

import (
	"errors"
	"fmt"
	"go.uber.org/zap"
	"os"
	"os/exec"
	"path"
)

type Database struct {
	appDir      string
	dataDir     string
	configPath  string
	user        string
	backupFile  string
	databaseDir string
	executor    *Executor
	logger      *zap.Logger
}

func NewDatabase(
	appDir string,
	dataDir string,
	configPath string,
	user string,
	executor *Executor,
	logger *zap.Logger,
) *Database {
	return &Database{
		appDir:      appDir,
		dataDir:     dataDir,
		configPath:  configPath,
		user:        user,
		backupFile:  path.Join(dataDir, "database.dump"),
		databaseDir: path.Join(dataDir, "database"),
		executor:    executor,
		logger:      logger,
	}
}

func (d *Database) DatabaseDir() string {
	return d.databaseDir
}

func (d *Database) Remove() error {
	if _, err := os.Stat(d.backupFile); errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("backup file does not exist: %s", d.backupFile)
	}
	_ = os.RemoveAll(d.databaseDir)
	return nil
}

func (d *Database) Init() error {
	cmd := exec.Command(
		fmt.Sprintf("%s/bin/initdb.sh", d.appDir),
		fmt.Sprintf("--user=%s", d.user),
		fmt.Sprintf("--basedir=%s/mariadb/usr", d.appDir),
		fmt.Sprintf("--datadir=%s", d.databaseDir),
	)
	out, err := cmd.CombinedOutput()
	d.logger.Info(cmd.String(), zap.ByteString("output", out))
	if err != nil {
		d.logger.Error(cmd.String(), zap.String("error", "failed to init database"))
	}
	return err
}

func (d *Database) Execute(sql string) error {
	return d.executor.Run(
		fmt.Sprintf("%s/sql", d.appDir),
		fmt.Sprintf("-e=%s", sql),
	)
}

func (d *Database) Restore() error {
	return d.executor.Run(
		fmt.Sprintf("%s/mariadb/usr/bin/mariadb", d.appDir),
		fmt.Sprintf("--user=%s", App),
		fmt.Sprintf("--password=%s", App),
		fmt.Sprintf("--execute='source %s'", d.backupFile),
	)
}

func (d *Database) Backup() error {
	return d.executor.Run(
		fmt.Sprintf("%s/mariadb/usr/bin/mariadb-dump", d.appDir),
		fmt.Sprintf("--user=%s", App),
		fmt.Sprintf("--password=%s", App),
		"--lock-tables",
		fmt.Sprintf("--databases=%s", App),
		fmt.Sprintf("--result-file=%s", d.backupFile),
		"run", "peertube.pgdumpall",
		"-f", d.backupFile,
	)
}

func (d *Database) createDb() error {
	err := d.Execute(fmt.Sprintf("CREATE DATABASE %s", App))
	if err != nil {
		return err
	}
	err = d.Execute(fmt.Sprintf("GRANT ALL PRIVILEGES ON %s.* TO \"%s\"@\"localhost\" IDENTIFIED BY \"%s\"", App, App, App))
	if err != nil {
		return err
	}
	err = d.Execute("FLUSH PRIVILEGES")
	if err != nil {
		return err
	}
	return nil
}
