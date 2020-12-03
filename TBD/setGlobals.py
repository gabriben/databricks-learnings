import os
import shutil

dir = "/databricks/driver/globals/"
if os.path.exists(dir):
    shutil.rmtree(dir)
os.makedirs(dir)
os.makedirs(dir + "globals")

import textwrap
g = textwrap.dedent("""\
CHANNELS = 3
IMG_SIZE = 224""") # avoid indentation on second line

s = textwrap.dedent("""\
from setuptools import setup

setup(name='globals',
      version='0.1',
      description='set globals',
      url='',
      author='Flying Circus',
      author_email='flyingcircus@example.com',
      license='MIT',
      packages=['globals'],
      zip_safe=False)
""")

with open("/databricks/driver/globals/globals/__init__.py", "w") as f: # w to overwrite
    f.write(g)
with open("/databricks/driver/globals/setup.py", "w") as f: # w to overwrite
    f.write(s)

%pip install -e /databricks/driver/globals
