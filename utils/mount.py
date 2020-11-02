# mount a bucket if it not already mounted

def mnt(bucket):
  folder = bucket.split("/",1)[-1]
  m = dbutils.fs.mounts()
  if(not any('/mnt/' + folder in s for s in m)): 
    dbutils.fs.mount("s3a://" + bucket, '/mnt/' + folder)
    display(dbutils.fs.ls('/mnt/' + folder))
