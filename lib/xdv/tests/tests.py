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
import unittest

import xdv.compiler
import xdv.run

if __name__ == '__main__':
    __file__ = sys.argv[0]

HERE = os.path.abspath(os.path.dirname(__file__))

class XDVTestCase(unittest.TestCase):
    writefiles = False

    testdir = None # override
    
    def testAll(self):
        self.errors = StringIO()
        themefn = os.path.join(self.testdir, "theme.html")
        contentfn = os.path.join(self.testdir, "content.html")
        rulesfn = os.path.join(self.testdir, "rules.xml")
        xpathsfn = os.path.join(self.testdir, "xpaths.txt")
        xslfn = os.path.join(self.testdir, "compiled.xsl")
        outputfn = os.path.join(self.testdir, "output.html")

        contentdoc = etree.parse(source=contentfn, base_url=contentfn,
                                       parser=etree.HTMLParser())

        # Make a compiled version
        theme_parser = etree.HTMLParser()
        ct = xdv.compiler.compile_theme(rules=rulesfn, theme=themefn, parser=theme_parser)
        
        # Serialize / parse the theme - this can catch problems with escaping.
        cts = etree.tostring(ct)
        parser = etree.XMLParser()
        ct2 = etree.fromstring(cts, parser=parser)

        # Compare to previous version
        if os.path.exists(xslfn):
            old = open(xslfn).read()
            new = cts
            if old != new:
                print >>self.errors, "WARNING:", "compiled.xsl has CHANGED"
                for line in difflib.unified_diff(old.split('\n'), new.split('\n'), xslfn, 'now'):
                    print >>self.errors, line
                if self.writefiles:
                    open(xslfn + '.old', 'w').write(old)

        # Write the compiled xsl out to catch unexpected changes
        if self.writefiles:
            open(xslfn, 'w').write(cts)

        # Apply the compiled version, then test against desired output
        theme_parser.resolvers.add(xdv.run.RunResolver(self.testdir))
        processor = etree.XSLT(ct)
        result = processor(contentdoc)
        # Read the whole thing to strip off xhtml namespace.
        # If we had xslt 2.0 then we could use xpath-default-namespace.
        self.themed_string = etree.tostring(result)
        self.themed_content = etree.ElementTree(file=StringIO(self.themed_string), 
                                                parser=etree.HTMLParser())

        # remove the extra meta content type
        meta = self.themed_content.xpath("/html/head/meta[@http-equiv='Content-Type']")[0]
        meta.getparent().remove(meta)

        if os.path.exists(xpathsfn):
            # xp = "/html/head/*[position()='1']/@id"
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
                if self.writefiles:
                    open(outputfn + '.old', 'w').write(old)

        # Write the compiled xsl out to catch unexpected changes
        if self.writefiles:
            open(outputfn, 'w').write(self.themed_string)

def main(*args, **kwargs):
    try:
        test_num = sys.argv[1]
    except IndexError:
        test_num = 1
        errors = 0
        while True:
            directory = os.path.join(HERE, '%03d' % test_num)
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

def test_suite():
    suite = unittest.TestSuite()
    for name in os.listdir(HERE):
        if name.startswith('.'):
            continue
        path = os.path.join(HERE, name)
        if not os.path.isdir(path):
            continue
        cls = type('Test%s'%name, (XDVTestCase,), dict(testdir=path))
        suite.addTest(unittest.makeSuite(cls))
    return suite


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
