#
# Simple test runner for validating different xdv scenarios
#

from lxml import etree
import os
import sys
import traceback
import difflib
from StringIO import StringIO
import unittest
import ConfigParser
import pkg_resources

import xdv.compiler
import xdv.run

if __name__ == '__main__':
    __file__ = sys.argv[0]

HERE = os.path.abspath(os.path.dirname(__file__))

defaultsfn = pkg_resources.resource_filename('xdv.tests', 'default-options.cfg')

class XDVTestCase(unittest.TestCase):
    
    writefiles = os.environ.get('XDVTESTS_WRITE_FILES', False)
    warnings = os.environ.get('XDVTESTS_WARN', "1").lower() not in ('0', 'false', 'off') 

    testdir = None # override
    
    def testAll(self):
        self.errors = StringIO()
        config = ConfigParser.ConfigParser()
        config.read([defaultsfn, os.path.join(self.testdir, "options.cfg")])
        
        themefn = None
        if config.get('xdvtest', 'theme'):
            themefn = os.path.join(self.testdir, config.get('xdvtest', 'theme'))
        contentfn = os.path.join(self.testdir, "content.html")
        rulesfn = os.path.join(self.testdir, "rules.xml")
        xpathsfn = os.path.join(self.testdir, "xpaths.txt")
        xslfn = os.path.join(self.testdir, "compiled.xsl")
        outputfn = os.path.join(self.testdir, "output.html")
        
        contentdoc = etree.parse(source=contentfn, base_url=contentfn,
                                       parser=etree.HTMLParser())

        # Make a compiled version
        theme_parser = etree.HTMLParser()
        ct = xdv.compiler.compile_theme(
            rules=rulesfn,
            theme=themefn,
            parser=theme_parser,
            absolute_prefix=config.get('xdvtest', 'absolute-prefix'),
            includemode=config.get('xdvtest', 'includemode'),
            )
        
        # Serialize / parse the theme - this can catch problems with escaping.
        cts = etree.tostring(ct)
        parser = etree.XMLParser()
        etree.fromstring(cts, parser=parser)

        # Compare to previous version
        if os.path.exists(xslfn):
            old = open(xslfn).read()
            new = cts
            if old != new:
                if self.writefiles:
                    open(xslfn + '.old', 'w').write(old)
                if self.warnings:
                    print "WARNING:", "compiled.xsl has CHANGED"
                    for line in difflib.unified_diff(old.split('\n'), new.split('\n'), xslfn, 'now'):
                        print line

        # Write the compiled xsl out to catch unexpected changes
        if self.writefiles:
            open(xslfn, 'w').write(cts)

        # Apply the compiled version, then test against desired output
        theme_parser.resolvers.add(xdv.run.RunResolver(self.testdir))
        processor = etree.XSLT(ct)
        result = processor(contentdoc)

        # Read the whole thing to strip off xhtml namespace.
        # If we had xslt 2.0 then we could use xpath-default-namespace.
        self.themed_string = etree.tostring(result, encoding="UTF-8", pretty_print=config.getboolean('xdvtest', 'pretty-print'))
        self.themed_content = etree.ElementTree(file=StringIO(self.themed_string), 
                                                parser=etree.HTMLParser())

        # remove the extra meta content type

        metas = self.themed_content.xpath("/html/head/meta[@http-equiv='Content-Type']")
        if metas:
            meta = metas[0]
            meta.getparent().remove(meta)

        if os.path.exists(xpathsfn):
            for xpath in open(xpathsfn).readlines():
                # Read the XPaths from the file, skipping blank lines and
                # comments
                this_xpath = xpath.strip()
                if not this_xpath or this_xpath[0] == '#':
                    continue
                assert self.themed_content.xpath(this_xpath), "%s: %s" % (xpathsfn, this_xpath)

        # Compare to previous version
        if os.path.exists(outputfn):
            old = open(outputfn).read()
            new = self.themed_string
            if old != new:
                #if self.writefiles:
                #    open(outputfn + '.old', 'w').write(old)
                for line in difflib.unified_diff(old.split('\n'), new.split('\n'), outputfn, 'now'):
                    print  line
                assert old == new, "output.html has CHANGED"

        # Write out the result to catch unexpected changes
        if self.writefiles:
            open(outputfn, 'w').write(self.themed_string)


def test_suite():
    suite = unittest.TestSuite()
    for name in os.listdir(HERE):
        if name.startswith('.'):
            continue
        path = os.path.join(HERE, name)
        if not os.path.isdir(path):
            continue
        cls = type('Test-%s'%name, (XDVTestCase,), dict(testdir=path))
        suite.addTest(unittest.makeSuite(cls))
    return suite
