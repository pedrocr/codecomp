#!/usr/bin/env python

from launchpadlib.launchpad import Launchpad
import os

# It's 2011, why is python defaulting to ascii for stdout? Backwards compatibility?
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

cachedir = os.path.abspath(os.path.join(os.path.dirname(__file__),"../lpcache"))
launchpad = Launchpad.login_anonymously('just testing', 'production', cachedir)
ubuntu = launchpad.distributions['ubuntu']
package = ubuntu.getSourcePackage(name='glibc')
bugs = package.searchTasks(status=["New", "Incomplete (with response)", "Incomplete (without response)", "Incomplete", "Opinion", "Invalid", "Won't Fix", "Expired", "Confirmed", "Triaged", "In Progress", "Fix Committed", "Fix Released"])

for bug in bugs:
  print bug.status
