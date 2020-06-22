#!/usr/bin/python

import argparse
import os
from bs4 import BeautifulSoup

parser = argparse.ArgumentParser()
parser.add_argument('xmlFile')
args = parser.parse_args()

pomFilePath = os.path.abspath(args.xmlFile)
# print(pomFilePath)
splitPath = pomFilePath.strip('/').split('/')
# print(splitPath)
moduleName = splitPath[-2]
# print(moduleName)
projectName = "{}.{}".format(splitPath[splitPath.index('idflakies') + 1],
                             splitPath[splitPath.index('idflakies') + 2])
# print(projectName)

pomFile = open(args.xmlFile, "r+")
contents = pomFile.read()
soup = BeautifulSoup(contents, 'xml')

tagToAdd = soup.new_tag("plugin")
groupIdTag = soup.new_tag("groupId")
groupIdTag.string = "org.apache.maven.plugins"
artifactIdTag = soup.new_tag("artifactId")
artifactIdTag.string = "maven-surefire-plugin"
versionTag = soup.new_tag("version")
versionTag.string = "2.22.0"
configurationTag = soup.new_tag("configuration")
reportsDirectoryTag = soup.new_tag("reportsDirectory")
reportsDirectoryString = "/Scratch/{}_output/{}/${{env.mvnTestRound}}".format(projectName, moduleName)
reportsDirectoryTag.string = reportsDirectoryString

configurationTag.append(reportsDirectoryTag)
tagToAdd.append(groupIdTag)
tagToAdd.append(artifactIdTag)
tagToAdd.append(versionTag)
tagToAdd.append(configurationTag)

allSurefirePlugins = soup.project.build.plugins.find("artifactId", string="maven-surefire-plugin")
if (allSurefirePlugins is None):
    if (soup.project.build.plugins is None):
        pluginsTag = soup.new_tag("plugins")
        pluginsTag.append(tagToAdd)
        if (soup.project.build is None):
            buildTag = soup.new_tag("build")
            buildTag.append(pluginsTag)
            soup.project.append(buildTag)
        else:
            soup.project.build.append(pluginsTag)
    else:
        soup.project.build.plugins.append(tagToAdd)
else:
    if (len(allSurefirePlugins) > 1):
        print("WARNING: {} surefire plugins found. Chosing the first one..."
              .format(len(allSurefirePlugins)))
    surefirePlugin = soup.project.build.plugins.find("artifactId", string="maven-surefire-plugin").find_parent("plugin")
    if (surefirePlugin.configuration is None):
        surefirePlugin.append(configurationTag)
    else:
        if (surefirePlugin.configuration.reportsDirectory is None):
            surefirePlugin.configuration.append(reportsDirectoryTag)
        else:
            surefirePlugin.configuration.reportsDirectory.string = reportsDirectoryString

pomFile.close()

newPom = soup.prettify("utf-8")
with open(args.xmlFile, "wb") as file:
        file.write(newPom)
