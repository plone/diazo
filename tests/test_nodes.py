#
# Simple test runner for validating different xdv scenarios
#

from lxml import etree
import os
import sys
import traceback
import pdb
import difflib
from StringIO import StringIO

if __name__ == '__main__':
    __file__ = sys.argv[0]

_HERE = os.path.abspath(os.path.dirname(__file__))

class XDV:
    access_control = etree.XSLTAccessControl(read_file=True)
    
    def __init__(self, testdir, debug=False, writefiles=False):
        self.errors = StringIO()
        themefn = os.path.join(testdir, "theme.html")
        contentfn = os.path.join(testdir, "content.html")
        rulesfn = os.path.join(testdir, "rules.xml")
        xpathsfn = os.path.join(testdir, "xpaths.txt")
        xslfn = os.path.join(testdir, "compiled.xsl")
        outputfn = os.path.join(testdir, "output.html")

        themedoc = etree.ElementTree(file=themefn, 
                                     parser=etree.HTMLParser())
        contentdoc = etree.ElementTree(file=contentfn, 
                                       parser=etree.HTMLParser())
        compilerfn = os.path.join(os.path.dirname(_HERE), "compiler.xsl")
        compilerdoc = etree.ElementTree(file=compilerfn)
        compiler = etree.XSLT(compilerdoc)

        # Make a compiled version
        params = {
            'rulesuri': '"%s"' % rulesfn,
            }
        ct = compiler(themedoc, **params)
        
        # Serialize / parse the theme - this can catch problems with escaping.
        cts = etree.tostring(ct)
        ct = etree.fromstring(cts, base_url=contentfn) # XXX why does it take this as the base

        # Compare to previous version
        if os.path.exists(xslfn):
            old = open(xslfn).read()
            new = cts
            if old != new:
                print >>self.errors, "WARNING:", "compiled.xsl has CHANGED"
                for line in difflib.unified_diff(old.split('\n'), new.split('\n'), xslfn, 'now'):
                    print >>self.errors, line
                if writefiles:
                    open(xslfn + '.old', 'w').write(old)

        # Write the compiled xsl out to catch unexpected changes
        if writefiles:
            open(xslfn, 'w').write(cts)

        # If there were any messages from <xsl:message> in the
        # compiler step, print them to the console
        for msg in compiler.error_log:
            print >>self.errors, msg

        # Apply the compiled version, then test against desired output
        processor = etree.XSLT(ct, access_control=self.access_control)
        result = processor(contentdoc)
        # Read the whole thing to strip off xhtml namespace.
        # If we had xslt 2.0 then we could use xpath-default-namespace.
        self.themed_string = etree.tostring(result)
        self.themed_content = etree.ElementTree(file=StringIO(self.themed_string), 
                                                parser=etree.HTMLParser())

        # remove the extra meta content type
        meta = self.themed_content.xpath("/html/head/meta[@http-equiv='Content-Type']")[0]
        meta.getparent().remove(meta)

        xp = "/html/head/*[position()='1']/@id"
        for xpath in open(xpathsfn).readlines():
            # Read the XPaths from the file, skipping blank lines and
            # comments
            this_xpath = xpath.strip()
            if not this_xpath or this_xpath[0] == '#':
                continue
            if not self.themed_content.xpath(this_xpath):
                print >>self.errors, "FAIL:", this_xpath, "is FALSE"

        # Compare to previous version
        if os.path.exists(outputfn):
            old = open(outputfn).read()
            new = self.themed_string
            if old != new:
                print >>self.errors, "FAIL:", "output.html has CHANGED"
                for line in difflib.unified_diff(old.split('\n'), new.split('\n'), outputfn, 'now'):
                    print >>self.errors, line
                if writefiles:
                    open(outputfn + '.old', 'w').write(old)

        # Write the compiled xsl out to catch unexpected changes
        if writefiles:
            open(outputfn, 'w').write(self.themed_string)

def main(*args, **kwargs):
    try:
        test_num = sys.argv[1]
    except IndexError:
        test_num = 1
        errors = 0
        while True:
            directory = os.path.join(_HERE, '%03d' % test_num)
            if not os.path.isdir(directory):
                test_num -= 1
                break
            xdv = XDV(directory, *args, **kwargs)
            result = xdv.errors.getvalue()
            if result:
                print 'Error running test %s...' % directory 
                print result
                errors += 1
            test_num += 1
        print "Ran %s tests with %s errors." % (test_num, errors)
    else:
        test_dir = os.path.abspath(test_num)
        xdv = XDV(test_dir, *args, **kwargs)
        print xdv.themed_string
        errors = xdv.errors.getvalue()
        if errors:
            print
            print xdv.errors.getvalue()


if __name__ == "__main__":
    debug = '--debug' in sys.argv
    if debug:
        sys.argv.remove('--debug')
    writefiles = '--writefiles' in sys.argv
    if writefiles:
        sys.argv.remove('--writefiles')
    try:
        main(debug=debug, writefiles=writefiles)
    except:
        type, value, tb = sys.exc_info()
        traceback.print_exc()
        if debug:
            pdb.post_mortem(tb)
