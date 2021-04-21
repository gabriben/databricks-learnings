import os
import subprocess
import json
import itertools
import pdb 

# different GPUs

GPU4 = "g4dn.12xlarge"
GPU8 = "p2.8xlarge"
GPU16 = "p2.16xlarge"

# the error when running too many jobs
# Error: b'{"error_code":"QUOTA_EXCEEDED","message":"The quota for the number of jobs has been reached. The current quota is 1000. This quota is only applied to jobs created through the UI or through the /jobs/create endpoint, which are displayed in the Jobs UI. If this limit is hit, it is very likely some user programmatically created many jobs that only need to run once. In this case, we recommend to delete those jobs and to submit one-time job runs instead using the /jobs/runs/submit endpoint. There is no quota on the number of one-time job runs you can create. For more questions, please contact support."}'

# ACTUALLY I WWANNA RUN NOW WITH DIFFERENT PARAMETERS IF CONCURRENT RUNS IN THE SAME JOB ARE POSSIBLE
# THERE IS A PARAMETER IN THE JSON THAT SEEMS TO SIGNIFY THAT IT MIGHT BE POSSIBLE ALTHOUGH THE DOC SAYS ITS IMPOSSIBLE I THINK

def getRunStatus(r):
    s = subprocess.run(['databricks', 'runs', 'get', '--run-id', r],
                           stdout=subprocess.PIPE).stdout.decode('utf-8')
    s = json.loads(s)
    print(s["state"])

def runHypers(expName, refJson, hypers, gpuSpecs = None, runNow = True):
    # runNow runs with run now. you won't see these runs in the cli
    # EXAMPLE:
    # IDs = runHypers("myExp", "refJson.json", hypers, gpuSpecs = GPU16)
    # [getRunStatus(i) for i in IDs]

    IDs = []
    
    # put outside
    with open(refJson) as f:
        j = json.loads(f.read())

    # all combinations of hyperparameters
    hypersCombi = list(itertools.product(*list(hypers.values())))
    # if len(hypers) > 1:
    #     hypersCombi = list(itertools.product(*list(hypers.values())))
    # else:
    #     hypersCombi = next(iter(hypers.values()))

    if not os.path.isdir(expName):
        os.mkdir(expName)

    # pdb.set_trace()
    if not gpuSpecs is None:
        j["new_cluster"]["node_type_id"] = gpuSpecs

    # no idea what EBS is, but error message required it
    if gpuSpecs in ["p2.8xlarge", "p2.16xlarge"]:
        j["new_cluster"]["aws_attributes"]["ebs_volume_count"] = 1
        j["new_cluster"]["aws_attributes"]["ebs_volume_size"] = 32

    # iterate over each hyperparameter combination
    for i, p in enumerate(hypersCombi):
        print("running " + expName + str(i) + " with hypers " + ''.join(p))
        for k, h in enumerate(list(hypers.keys())):
            j["notebook_task"]['base_parameters'][h] = p[k]
        j["name"] = expName + str(i)
        path = expName + "/" + expName + str(i) + ".json"
        print(j["notebook_task"]['base_parameters'])
        with open(path, 'w') as f:
            json.dump(j, f)

        if runNow:
            s = subprocess.run(['databricks', 'runs', 'submit', '--json-file', path],
                               stdout=subprocess.PIPE).stdout.decode('utf-8')
            jobID = json.loads(s)
            IDs = IDs + [str(jobID['run_id'])]
            
        else:
            s = subprocess.run(['databricks', 'jobs', 'create', '--json-file', path],
                               stdout=subprocess.PIPE).stdout.decode('utf-8')

            jobID = json.loads(s)
            IDs = IDs + [str(jobID['job_id'])]
            
            s = subprocess.run(['databricks', 'jobs', 'run-now', '--job-id',
                            str(jobID['job_id'])], stdout=subprocess.PIPE).stdout.decode('utf-8')
        print(s)

    return(IDs)

