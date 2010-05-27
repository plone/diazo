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

import xdv.compiler
import xdv.run

if __name__ == '__main__':
    __file__ = sys.argv[0]

HERE = os.path.abspath(os.path.dirname(__file__))

class XDVTestCase(unittest.TestCase):
    
    writefiles = os.environ.get('XDVTESTS_WRITE_FILES', False)
    warnings = os.environ.get('XDVTESTS_WARN', "1").lower() not in ('0', 'false', 'off') 

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
        self.themed_string = etree.tostring(result, encoding="UTF-8", pretty_print=True)
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
                print "ERROR:", "output.html has CHANGED"
                for line in difflib.unified_diff(old.split('\n'), new.split('\n'), outputfn, 'now'):
                    print  line
                self.assertEquals(old, new)

        # Write out the result to catch unexpected changes
        if self.writefiles:
            open(outputfn, 'w').write(self.themed_string)
    
class TestAbsolutePrefix(unittest.TestCase):
    
    def testEnabled(self):
        themefn = os.path.join(HERE, "absolute_theme.html")
        rulesfn = os.path.join(HERE, "absolute_rules.xml")
        
        compiled = xdv.compiler.compile_theme(rules=rulesfn, theme=themefn, absolute_prefix="/abs")
        
        styleTag = compiled.xpath('//style')[0]
        styleLines = [x.strip() for x in styleTag.getchildren()[0].text.split('\n') if x.strip()]
        expectedLines = [
            '@import "/abs/foo.css";',
            '@import url("/abs/foo.css");',
            "@import url('/abs/foo.css');",
            "@import url('/foo.css');",
            "@import url('/foo.css');",
            "@import url('http://site.com/foo.css');"
            ]
        for line, expected in zip(styleLines, expectedLines):
            self.assertEquals(line, expected)
        
        linkTags = compiled.xpath('//link')
        self.assertEquals([
            '/abs/foo.css',
            '/abs/foo.css',
            '/foo.css',
            '/foo.css',
            'http://site.com/foo.css'
        ], [x.get('href') for x in linkTags])
        
        scriptTags = compiled.xpath('//script')
        self.assertEquals([
            '/abs/foo.js',
            '/abs/foo.js',
            '/foo.js',
            '/foo.js',
            'http://site.com/foo.js'
        ], [x.get('src') for x in scriptTags])
        
        imgTags = compiled.xpath('//img')
        self.assertEquals([
            '/abs/foo.jpg',
            '/abs/foo.jpg',
            '/foo.jpg',
            '/foo.jpg',
            'http://site.com/foo.jpg'
        ], [x.get('src') for x in imgTags])
        
        inputTags = compiled.xpath('//input')
        self.assertEquals([
            '/abs/foo.jpg',
            '/abs/foo.jpg',
            '/foo.jpg',
            '/foo.jpg',
            'http://site.com/foo.jpg'
        ], [x.get('src') for x in inputTags])
    
    def testDisabled(self):
        themefn = os.path.join(HERE, "absolute_theme.html")
        rulesfn = os.path.join(HERE, "absolute_rules.xml")
        
        compiled = xdv.compiler.compile_theme(rules=rulesfn, theme=themefn)
        
        styleTag = compiled.xpath('//style')[0]
        styleLines = [x.strip() for x in styleTag.getchildren()[0].text.split('\n') if x.strip()]
        expectedLines = [
            '@import "foo.css";',
            '@import url("foo.css");',
            "@import url('./foo.css');",
            "@import url('../foo.css');",
            "@import url('/foo.css');",
            "@import url('http://site.com/foo.css');"
            ]
        for line, expected in zip(styleLines, expectedLines):
            self.assertEquals(line, expected)
        
        linkTags = compiled.xpath('//link')
        self.assertEquals([
            'foo.css',
            './foo.css',
            '../foo.css',
            '/foo.css',
            'http://site.com/foo.css'
        ], [x.get('href') for x in linkTags])
        
        scriptTags = compiled.xpath('//script')
        self.assertEquals([
            'foo.js',
            './foo.js',
            '../foo.js',
            '/foo.js',
            'http://site.com/foo.js'
        ], [x.get('src') for x in scriptTags])
        
        imgTags = compiled.xpath('//img')
        self.assertEquals([
            'foo.jpg',
            './foo.jpg',
            '../foo.jpg',
            '/foo.jpg',
            'http://site.com/foo.jpg'
        ], [x.get('src') for x in imgTags])
        
        inputTags = compiled.xpath('//input')
        self.assertEquals([
            'foo.jpg',
            './foo.jpg',
            '../foo.jpg',
            '/foo.jpg',
            'http://site.com/foo.jpg'
        ], [x.get('src') for x in inputTags])


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
    suite.addTest(unittest.makeSuite(TestAbsolutePrefix))
    return suite
