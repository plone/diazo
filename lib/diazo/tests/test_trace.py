from StringIO import StringIO
import sys
import os.path
from lxml import etree

import diazo.runtrace
import diazo.compiler
import diazo.run

import unittest2 as unittest

if __name__ == '__main__':
    __file__ = sys.argv[0]

def testfile(filename):
    return os.path.join(os.path.abspath(os.path.dirname(__file__)), 'test_wsgi_files', filename)

class TestDebug(unittest.TestCase):
    rules_str = """\
<rules xmlns="http://namespaces.plone.org/diazo" xmlns:css="http://namespaces.plone.org/diazo/css" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <theme css:if-content="body.external">
    <html><body>
      <h1>External Theme</h1>
      <div class="cow">I am daisy the cow</div>
      <div class="pig">I am daisy the pig</div>
    </body></html>
  </theme>
  <rules if-content="/html/body[@id = 'theme-on']" useless="I need to be put before if-content processing">
      <replace css:content="div.bovine" css:theme="div.cow" css:if-content="body.female" />
      <replace css:content="div.bovine" css:theme="div.bull" css:if-content="body.male" />
      <replace css:content="div.pig" css:theme="div.pig" />
      <replace css:content="div.antelope" css:theme="div.antelope" />
  </rules>
</rules>
    """
    theme_str = """\
<html><body>
  <h1>Provided Theme</h1>
  <div class="cow">I am a template cow</div>
  <div class="bull">I am a template bull</div>
  <div class="pig">I am daisy the pig</div>
</body></html>
    """
    def compile(self):
        # Compile default rule and themes
        ct = diazo.compiler.compile_theme(
            rules=StringIO(self.rules_str),
            theme=StringIO(self.theme_str),
            indent=True,
            runtrace=True,
            )
        return etree.XSLT(ct)
    
    def test_internal(self):
        processor = self.compile()
        result = processor(etree.fromstring("""\
<html><body id="theme-on" class="male">
  <h1>Content</h1>
  <div class="bovine" id="#cow-daisy">I am frank the bull</div>
  <div class="pig" id="#pig-george">I am daisy the pig</div>
</body></html>
        """))
        runtrace_doc = diazo.runtrace.generate_runtrace(
            rules=StringIO(self.rules_str),
            error_log = processor.error_log,
        )
        self.assertXPath(runtrace_doc, "/d:rules/d:theme/@runtrace-if-content", "0")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/@runtrace-if-content", "1")
        # <replace css:content="div.bovine" css:theme="div.cow" css:if-content="body.female" />
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[1]/@runtrace-if-content", "0")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[1]/@runtrace-content", "1")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[1]/@runtrace-theme", "1")
        # <replace css:content="div.bovine" css:theme="div.bull" css:if-content="body.male" />
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[2]/@runtrace-if-content", "1")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[2]/@runtrace-content", "1")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[2]/@runtrace-theme", "1")
        # <replace css:content="div.pig" css:theme="div.pig" />
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[3]/@runtrace-content", "1")
        # <replace css:content="div.antelope" css:theme="div.antelope" />
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[4]/@runtrace-content", "0")
    
    def test_external(self):
        processor = self.compile()
        result = processor(etree.fromstring("""\
<html><body id="theme-on" class="female external">
  <h1>Content</h1>
  <div class="bovine" id="#cow-daisy">I am daisy the cow</div>
  <div class="pig" id="#pig-george">I am daisy the pig</div>
</body></html>
        """))
        runtrace_doc = diazo.runtrace.generate_runtrace(
            rules=StringIO(self.rules_str),
            error_log = processor.error_log,
        )
        self.assertXPath(runtrace_doc, "/d:rules/d:theme/@runtrace-if-content", "1")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/@runtrace-if-content", "1")
        # <replace css:content="div.bovine" css:theme="div.cow" css:if-content="body.female" />
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[1]/@runtrace-if-content", "1")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[1]/@runtrace-content", "1")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[1]/@runtrace-theme", "1")
        # <replace css:content="div.bovine" css:theme="div.bull" css:if-content="body.male" />
        # The external theme only has the cow slot
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[2]/@runtrace-if-content", "0")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[2]/@runtrace-content", "1")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[2]/@runtrace-theme", "0")
        # <replace css:content="div.pig" css:theme="div.pig" />
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[3]/@runtrace-content", "1")
        # <replace css:content="div.antelope" css:theme="div.antelope" />
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/d:replace[4]/@runtrace-content", "0")
    
    def assertXPath(self,doc,xpath,expected):
        self.assertEqual(
            doc.xpath(xpath, namespaces=(dict(d="http://namespaces.plone.org/diazo")))[0],
            expected
        )

def test_suite():
    return unittest.defaultTestLoader.loadTestsFromName(__name__)
