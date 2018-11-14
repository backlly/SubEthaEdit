#!/bin/sh

#  TCM_GenerateRevisionConfig.sh
#  Created by Michael Ehrmann on 21.10.13.

# this script needs to be included in the app build scheme prebuild phase using
# ${SRCROOT}/../TCMScripts/TCM_GenerateRevisionConfig.sh

# You can override TCM_WORKSPACE_ROOT to have a differnt repository layout. Default is having a BuildConfig folder on ../${SOURCE_ROOT}
# YOU CAN CHANGE THIS by defining custom build setting called TCM_WORKSPACE_ROOT

if [ -n "${TCM_WORKSPACE_ROOT}" ]; then
echo "TCM_WORKSPACE_ROOT set by project to ${TCM_WORKSPACE_ROOT}"
else
echo "TCM_WORKSPACE_ROOT not set by project, using ${SOURCE_ROOT}/../"
TCM_WORKSPACE_ROOT="${SOURCE_ROOT}/../"
fi


# generate app revision numbers
cd "${TCM_WORKSPACE_ROOT}"
REV_SHA1=`git rev-parse HEAD`

# count all the comits which make up the current revision we add 10.000 to this changecount to avoid collitions with former svn revision numbers
GIT_REV=`git rev-list HEAD | wc -l;`
REV=`echo $(( ${GIT_REV}+4000 ))` # adding 4000 to identify a GIT revision

if [ `git ls-files -m | wc -l` -gt 0 ]; then
if [ -n "$TCM_APP_STYLE" ]; then
	MODIFIED="+"
fi
fi

YEAR=`date +"%Y"`

cd -

REVISION_CONFIG_FILE="${TCM_WORKSPACE_ROOT}BuildConfig/TCMRevision.xcconfig"

echo "Writing to ${REVISION_CONFIG_FILE}"

echo "Current TCM_APP_REVISION ${TCM_APP_REVISION}"
echo "Current TCM_APP_REVISION_HASH ${TCM_APP_REVISION_HASH}"
echo "Current TCM_APP_BUILD_STYLE ${TCM_APP_BUILD_STYLE}"
echo "Current TCM_APP_BUILD_YEAR ${TCM_APP_BUILD_YEAR}"
echo "Current CONFIGURATION ${CONFIGURATION}"

echo "Setting new TCM_APP_REVISION ${REV}${MODIFIED}"
echo "Setting new TCM_APP_REVISION_HASH ${REV_SHA1}${MODIFIED}"
echo "Setting new TCM_APP_BUILD_STYLE ${CONFIGURATION}"
echo "Setting new TCM_APP_BUILD_YEAR ${YEAR}"

# Write the new config file
cat >"${REVISION_CONFIG_FILE}" <<EOL
//*********    AUTOGENERATED FILE    *********
//*********       DO NOT EDIT        *********

TCM_APP_REVISION = ${REV}${MODIFIED}
TCM_APP_REVISION_HASH = ${REV_SHA1}${MODIFIED}
TCM_APP_BUILD_STYLE = ${CONFIGURATION}
TCM_APP_BUILD_YEAR = ${YEAR}
EOL

# Mark the updated config file as unchanged for git
cd "${TCM_WORKSPACE_ROOT}"
git update-index --assume-unchanged "${REVISION_CONFIG_FILE}"
cd -

# Test if the final Info.plist needs to be removed, because a value changed
if [ -f "${CONFIGURATION_BUILD_DIR}/${INFOPLIST_PATH}" ]; then
echo "Info.plist exists, checking if update is needed."

# The Enviroment provides us the original values from a previous build.
if [ "${TCM_APP_REVISION}" != "${REV}${MODIFIED}" -o "${TCM_APP_REVISION_HASH}" != "${REV_SHA1}${MODIFIED}" -o "${TCM_APP_BUILD_STYLE}" != "${CONFIGURATION}" -o "${TCM_APP_BUILD_YEAR}" != "${YEAR}" ]; then
echo "Removing Info.plist from ${CONFIGURATION_BUILD_DIR}/${INFOPLIST_PATH}"
rm -f "${CONFIGURATION_BUILD_DIR}/${INFOPLIST_PATH}"
else
echo "Info.plist update not needed."
fi
fi
