import re
import glob

bver_re=re.compile("-v(([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9a-zA-Z]+)|$))")

semver_re=re.compile("^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$")

filenames=glob.glob("*")

for filename in filenames:
    try:
        bver_res=bver_re.search(str(filename))
        semver_res=semver_re.search(bver_res.group(1))
        #print(semver_res.group(0))
        print(str(semver_res.group(0))+" -> "+str(filename))
    except AttributeError as e:
        print("invalid -> "+str(filename))

    #print(semver_res)
