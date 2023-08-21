package pkg

import (
	cp "github.com/otiai10/copy"
	"hooks/pkg/platform"
	"os"
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
	database           Database
}

func New() *Installer {
	configDir := path.Join(DataDir, "config")
	return &Installer{
		newVersionFile:     path.Join(AppDir, "version"),
		currentVersionFile: path.Join(DataDir, "version"),
		configDir:          configDir,
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
	err = os.Mkdir(path.Join(storageDir, "cache"), 0755)
	if err != nil {
		return err
	}
	err = os.Mkdir(path.Join(storageDir, "photos"), 0755)
	if err != nil {
		return err
	}
	err = os.Mkdir(path.Join(storageDir, "temp"), 0755)
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
