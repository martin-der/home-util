# MDU Shell tools

## Configuration

Running the script `home-init.sh` will initialize the user home directory.
The behavior of this script is controlled by the file `.config/mdu/init.properties`

Sample configuration :

```properties
directory.project.dev=$HOME/dev/project
directory.bin=$HOME/bin
directory.local=$HOME/local
#directory.opt=$HOME/opt

# If bin folder is defined
# then those Links will be created in the bin folder
link.executable.sourceDirectory=$HOME/dev/prog
link.executable.elements=home-util/shell-util.sh\
home-util/config-util.sh\
home-util/completion-helper.sh\
home-util/opt-admin.sh\
home-util/mdu-git.sh\
home-util/mkGitArchive.sh\
home-util/json-manipulate.py
# The following links will be created
# They can be relative or absolute
link.elements=$HOME/my-dir->my-nested/and/very-long/directory\
$HOME/icons->/usr/share/icons\
$HOME/fun-music->$HOME/music/genre/misc
```

## environment variables

### Logging related varialbes

#### MDU_LOG_LEVEL ( or LOG_LEVEL )

Set the level of logging. Can be one of

* debug
* info
* warn 
* error
* none

```shell
MDU_LOG_LEVEL=info
```

#### MDU_LOG_STDOUT and MDU_LOG_STDERR

If `MDU_LOG_STDOUT` is set and not empty, debug and info output are redirected to the file defined by `$MDU_LOG_STDOUT`.

If `MDU_LOG_STDERR` is set and not empty, warning and error output are redirected to the file defined by `$MDU_LOG_STDERR`.

------

### MDU_SOURCE_OPTIONS

A list of characters controlling the way sourcing is done

* when encountering an already sourced script
  * 1 : don't include it again
  * n : include it again


Use by shell-util > load_script,load_script_once


defaults to

```shell
MDU_SOURCE_OPTION=1
```

------

### MDU_BUP_DIRECTORY

```shell
MDU_BUP_DIRECTORY=/home/myuser/data/backup
```

Used by

* mkGitArchive

------

### MDU_OPT_DIRECTORY

Used by

* opt-admin
 
```shell
MDU_OPT_DIRECTORY=/home/myuser/opt
```

------


### Environment dependent


```shell
MDU_NOTIFY=notify-send
MDU_ICON_ERROR=/usr/share/icons/Humanity/status/32/error.svg
MDU_ICON_WARN=/usr/share/icons/Humanity/status/32/dialog-warning.svg
MDU_ICON_INFO=/usr/share/icons/Humanity/status/32/info.svg
```
