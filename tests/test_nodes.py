#
# Simple test runner for validating different xdv scenarios
#

from lxml import etree
import os
import sys

_HERE = os.path.abspath(os.path.dirname(__file__))

class XDV:

    def __init__(self, testnumber):
        testnumber = testnumber
        themefn = "%s/theme.html"           % testnumber
        contentfn = "%s/content.html"       % testnumber
        rulesfn = os.path.join(_HERE, "%s/rules.xml" % testnumber)
        xpathsfn = "%s/xpaths.txt"            % testnumber

        themedoc = etree.ElementTree(file=themefn, 
                                     parser=etree.HTMLParser())
        contentdoc = etree.ElementTree(file=contentfn, 
                                       parser=etree.HTMLParser())
        compilerfn = "../compiler.xsl"
        compilerdoc = etree.ElementTree(file=compilerfn)
        compiler = etree.XSLT(compilerdoc)

        # Make a compiled version
        params = {
            'rulesuri': '"%s"' % rulesfn,
            }
        ct = compiler(themedoc, **params)

        # If there were any messages from <xsl:message> in the
        # compiler step, print them to the console
        for msg in compiler.error_log:
            print msg

        # Apply the compiled version, then test against desired output
        processor = etree.XSLT(ct)
        self.themed_content = processor(contentdoc)
        xp = "/html/head/*[position()='1']/@id"
        for xpath in open(xpathsfn).readlines():
            # Read the XPaths from the file, skipping blank lines and
            # comments
            this_xpath = xpath.strip()
            if not this_xpath or this_xpath[0] == '#':
                continue
            if not self.themed_content.xpath(this_xpath):
                print "FAIL:", this_xpath, "is FALSE"

        # Make a serialization
        self.themed_string = str(self.themed_content)

def main():
    test_num = sys.argv[1]
    xdv = XDV(test_num)
#    print xdv.themed_string


if __name__ == "__main__":
    main()
