#!/usr/bin/env python

import sys
import yaml

for (key, value) in yaml.load(open(sys.argv[1]), Loader = yaml.SafeLoader)['nodes'].iteritems():
  if value['status'] == 'Error':
    print value['log']
