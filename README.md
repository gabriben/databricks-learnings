# Databricks

- live notebook clusters :: block by block code execution
- standard clusters :: job execution

## install a package on a live notebook cluster from the pypi repository

go to main page -> import library -> pypi -> "package_name"

whenever you restart the cluster, you have to reinstall farm:
uninstall (go to workspace -> "farm" -> uninstall) -> restart cluster -> install (go to workspace -> "farm" -> install)

Once one is done testing, it is easier to move to a standard cluster, so as to start scheduling and always have the packages installed.

## install a package on a standard cluster from the pypi repository

create a job -> associate a clsuter to it -> add a dependent library that was imported with the steps above.

## hyperparameter tuning

https://docs.databricks.com/notebooks/widgets.html

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

## silence the message "py4j.java_gateway -   Received command c on object id p0" in the logs

```
import logging
logger = spark._jvm.org.apache.log4j
logging.getLogger("py4j").setLevel(logging.ERROR)
```
