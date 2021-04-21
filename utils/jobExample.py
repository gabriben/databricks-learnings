from launchJob import runHypers
from launchJob import getRunStatus

hypers = {
    "BATCH_SIZE" : ["3"],
    "EPOCHS" : ["32"]
}

IDs = runHypers("myExp", "jsonAzureExample.json", hypers)

[getRunStatus(i) for i in IDs]

hypers.values() = [str(v) for v in hypers.values()]

import itertools

list(itertools.product(*list(hypers.values())))
