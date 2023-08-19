package pkg

import (
	"errors"
	"fmt"
	cp "github.com/otiai10/copy"
	"go.uber.org/zap"
	"io/fs"
	"os"
	"os/exec"
	"path"
)

type Database struct {
	appDir           string
	backupFile       string
	configPath       string
	dataDir          string
	postgresqlConfig string
	databaseDir      string
	databaseHost     string
	logger           *zap.Logger
}

func NewDatabase(appDir, dataDir, configPath string, port int, logger *zap.Logger) *Database {
	databaseDir := path.Join(dataDir, "database")
	return &Database{
		appDir:           appDir,
		configPath:       configPath,
		dataDir:          dataDir,
		postgresqlConfig: path.Join(configPath, "postgresql.conf"),
		databaseDir:      databaseDir,
		backupFile:       path.Join(dataDir, "database.dump"),
		databaseHost:     fmt.Sprintf("%s:%d", databaseDir, port),
		logger:           logger,
	}
}

func (d *Database) remove() error {
	if _, err := os.Stat(d.backupFile); errors.Is(err, fs.ErrNotExist) {
		return fmt.Errorf("backup file does not exist: %s", d.backupFile)
	}

	if dir, err := os.Stat(d.databaseDir); err == nil {
		if dir.IsDir() {
			err = os.RemoveAll(d.databaseDir)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

func (d *Database) init() error {
	return d.run(path.Join(d.appDir, "bin/initdb.sh", d.databaseDir))
}

func (d *Database) run(name string, args ...string) error {
	command := exec.Command(name, args...)
	d.logger.Info("execute", zap.String("cmd", command.String()))
	output, err := command.CombinedOutput()
	d.logger.Info("execute", zap.String("output", string(output)))
	return err
}

func (d *Database) initConfig() error {
	return cp.Copy(d.postgresqlConfig, d.databaseDir)
}

func (d *Database) execute(database, user, sql string) error {
	return d.run("snap", "run", "photoprism.psql", "-U", user, "-d", database, "-c", sql)
}

func (d *Database) restore() error {
	return d.run("snap", "run", "photoprism.psql", "-f", d.backupFile, "postgres")
}

func (d *Database) backup() error {
	return d.run("snap", "run", "photoprism.pgdumpall", "-f", d.backupFile)
}
