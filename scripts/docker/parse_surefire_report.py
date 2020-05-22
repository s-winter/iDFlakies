from bs4 import BeautifulSoup
import os
import sys

def output_xml_results(xml_file):
    with open(xml_file[1]) as fp:
        y=BeautifulSoup(fp, features="xml")
        # print str(y)
        for f in y.testsuite.findAll("testcase"):
            s = "unknown"
            if f.find('failure'):
                s = "failure"
            elif f.find('error'):
                s = "error"
            else:
                s = "pass"
            print str.format("{}.{},{},{},{},{}", f["classname"], f["name"], s, f["time"], xml_file[2], xml_file[1])

if __name__ == '__main__':
    output_xml_results(sys.argv)
