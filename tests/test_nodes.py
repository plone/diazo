#
# Simple test runner for validating different xdv scenarios
#

from lxml import etree
import os
import sys
from StringIO import StringIO

_HERE = os.path.abspath(os.path.dirname(__file__))

class XDV:

    def __init__(self, testnumber):
        self.errors = StringIO()
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
            print >>self.errors, msg

        # Apply the compiled version, then test against desired output
        processor = etree.XSLT(ct)
        result = processor(contentdoc)
        # Read the whole thing to strip off xhtml namespace.
        # If we had xslt 2.0 then we could use xpath-default-namespace.
        self.themed_content = etree.ElementTree(file=StringIO(str(result)), 
                                                parser=etree.HTMLParser())
        
        xp = "/html/head/*[position()='1']/@id"
        for xpath in open(xpathsfn).readlines():
            # Read the XPaths from the file, skipping blank lines and
            # comments
            this_xpath = xpath.strip()
            if not this_xpath or this_xpath[0] == '#':
                continue
            if not self.themed_content.xpath(this_xpath):
                print >>self.errors, "FAIL:", this_xpath, "is FALSE"

        # Make a serialization
        self.themed_string = str(self.themed_content)

def main():
    try:
        test_num = sys.argv[1]
    except IndexError:
        test_num = 1
        errors = 0
        while True:
            directory = '%03d' % test_num
            if not os.path.isdir(directory):
                test_num -= 1
                break
            xdv = XDV(directory)
            result = xdv.errors.getvalue()
            if result:
                print 'Error running test %s...' % directory 
                print result
                errors += 1
            test_num += 1
        print "Ran %s tests with %s errors." % (test_num, errors)
    else:
        xdv = XDV(test_num)
        print xdv.themed_string


if __name__ == "__main__":
    main()
