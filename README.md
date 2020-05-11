# Databricks

- live notebook clusters :: block by block code execution
- standard job clusters :: job execution (~3-4 times cheaper)

## miscellanious

- path to root: `file:/databricks/driver/`
- use your own IDE (e.g. Jupyterlab): https://databricks.com/blog/2019/12/03/jupyterlab-databricks-integration-bridge-local-and-remote-workflows.html
- the comment/uncomment shortcut `Ctrl` + `/` doesn't work with German / Swiss mac keyboards. 
-> **Swiss fix** `Ctrl` + `-`. 
-> **German fix** ??

## Jobs

- chose a new job cluster (the all purpose ones are more expensive and can also be notebook clusters).
- Saving logs: advanced options -> logging -> destination -> DBFS

## Databricks + AWS

### permanently mount a bucket (notebook and job clusters are handled differently)

```
bucket = "path/to/bucket"
mount = "folder_name"

# mount if not already mounted
m = dbutils.fs.mounts()
if(not any('/mnt/' + mount in s for s in m)):
  dbutils.fs.mount("s3a://" + bucket, '/mnt/' + mount)
  display(dbutils.fs.ls('/mnt/' + mount))
```

### temporarily copy from a bucket (while cluster is active)

```
dbutils.fs.cp("s3a://path/to/bucket", "file:/databricks/driver/", True)
```

## download files from folder

1. go to user settings under the little man top right. setup a new token

2. in terminal:

```
pip install databricks-cli
databricks configure --token
westeurope.azuredatabricks.net/?o=5728379491119130
```

3. copy paste the token

---

- for help:

```
databricks fs -h
```

- to download a file:

```
databricks fs cp dbfs:/FileStore/... local/file/directory
```


## For Python

### import a .py file as a module

1. right click in the workspace and click import (creating a .py file from scratch is not possible)
2. write `%run /Users/firstName.lastName@company.com/path/to/external.py` in a notebook block.

### install a package on a live notebook cluster from the pypi repository

go to main page -> import library -> pypi -> "package_name"

whenever you restart the cluster that is attached to the notebook, you have to "detach reattach" to the cluster on the upper left corner.

 <!--- 
, you have to reinstall farm:
 uninstall (go to workspace -> "farm" -> uninstall) -> restart cluster -> install (go to workspace -> "farm" -> install)
just --->

Once one is done testing, it is easier to move to a standard cluster, so as to start scheduling and always have the packages installed.

### install a package on a standard cluster from the pypi repository

create a job -> associate a clsuter to it -> add a dependent library that was imported with the steps above.

### hyperparameter tuning

https://docs.databricks.com/notebooks/widgets.html


### silence the message "py4j.java_gateway -   Received command c on object id p0" in the logs

```
import logging
logger = spark._jvm.org.apache.log4j
logging.getLogger("py4j").setLevel(logging.ERROR)
```

## For R

### Install and Load Packages dynamically

```
packages <- c("data.table", "profvis", ...)

package.check <- lapply(packages, FUN = function(x) {
  if (!require(x, character.only = T)) install.packages(x)
  if (! (x %in% (.packages() )))  library(x, character.only = T)
})
```


### install Keras

```
# making sure that the cluster's default python is used to install keras and run models
# without this command, keras_model.compile(), install_keras() and install_tensorflow() conflict by using different python installations.
Sys.setenv(RETICULATE_PYTHON = system("which python", intern = T))

install.packages("tensorflow")
library(tensorflow)
install_tensorflow()

# version = "gpu"

install.packages("keras")
library(keras)
install_keras(tensorflow = "gpu")

### check

k = backend()
sess = k$get_session()
sess$list_devices()
```

### workflow example

Databricks does not offer an integration of an entire github repo. Instead, it works on a file by file basis. To manage that, to use your favourite IDE and to separate the script into several text files for readability (e.g. one text file per function / class definition), one solution is the following:
Have a central R notebook on databricks that calls scripts from other R files in a central ```script```directory. Workflow is then the following:
1. modify script files locally on favourite IDE
2. in your shell (to install the CLI, see "download files from folder"): 
  ```
  databricks fs mkdirs dbfs:/FileStore/video2vec/script
  databricks fs cp -r script dbfs:/FileStore/video2vec/script
  ```
3. in databricks
  ```
  setwd("/dbfs/FileStore/video2vec/script")
  lapply(list.files(pattern = "[.][rR]$", recursive = FALSE), source)
  ```

Another option is an R-Package, but that would have required an extra step of de- and re-installing the package at every modification.
This workflow sounds a bit more tedious than usual, but requires just a few seconds of time and is not that much slower than full repo git integration (until it comes to Databricks). Please do message me in case you found a nicer workflow for R or Python. 
