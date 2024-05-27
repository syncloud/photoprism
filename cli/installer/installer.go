package installer

import (
	cp "github.com/otiai10/copy"
	"github.com/syncloud/golib/platform"
	"go.uber.org/zap"
	"hooks/log"
	"os"
	"os/exec"
	"path"
)

const (
	App       = "photoprism"
	AppDir    = "/snap/photoprism/current"
	DataDir   = "/var/snap/photoprism/current"
	CommonDir = "/var/snap/photoprism/common"
)

type Installer struct {
	newVersionFile     string
	currentVersionFile string
	configDir          string
	platformClient     *platform.Client
	logger             *zap.Logger
}

func New() *Installer {
	configDir := path.Join(DataDir, "config")
	return &Installer{
		newVersionFile:     path.Join(AppDir, "version"),
		currentVersionFile: path.Join(DataDir, "version"),
		configDir:          configDir,
		platformClient:     platform.New(),
		logger:             log.Logger(),
	}
}

func (i *Installer) Install() error {
	err := CreateUser(App)
	if err != nil {
		return err
	}

	err = i.UpdateConfigs()
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}

	err = i.StorageChange()
	if err != nil {
		return err
	}
	return nil
}

func (i *Installer) Configure() error {
	return i.UpdateVersion()
}

func (i *Installer) PreRefresh() error {
	return nil
}

func (i *Installer) PostRefresh() error {
	err := i.UpdateConfigs()
	if err != nil {
		return err
	}

	err = i.ClearVersion()
	if err != nil {
		return err
	}

	command := exec.Command("snap", "run", "photoprism.sqlite", "update auth_users set webdav=1 where id > 1;")
	output, err := command.CombinedOutput()
	i.logger.Info("sqlite", zap.String("output", string(output)))
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}
	return nil

}
func (i *Installer) StorageChange() error {
	storageDir, err := platform.New().InitStorage(App, App)
	if err != nil {
		return err
	}
	err = Chown(storageDir, App)
	if err != nil {
		return err
	}
	return nil
}

func (i *Installer) ClearVersion() error {
	return os.RemoveAll(i.currentVersionFile)
}

func (i *Installer) UpdateVersion() error {
	return cp.Copy(i.newVersionFile, i.currentVersionFile)
}

func (i *Installer) UpdateConfigs() error {
	return cp.Copy(path.Join(AppDir, "config"), path.Join(DataDir, "config"))
}

func (i *Installer) FixPermissions() error {
	err := Chown(DataDir, App)
	if err != nil {
		return err
	}
	err = Chown(CommonDir, App)
	if err != nil {
		return err
	}
	return nil
}
