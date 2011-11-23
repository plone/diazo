from StringIO import StringIO
import sys
import os.path
from lxml import etree

import diazo.compiler
import diazo.run

import unittest2 as unittest

if __name__ == '__main__':
    __file__ = sys.argv[0]

def testfile(filename):
    return os.path.join(os.path.abspath(os.path.dirname(__file__)), 'test_wsgi_files', filename)

class TestDebug(unittest.TestCase):
    
    def test_camels(self):
        content_str = """\
<html><body id="theme-on" class="external">
  <h1>Content</h1>
  <div class="cow" id="#cow-daisy">I am daisy the cow</div>
  <div class="pig" id="#pig-george">I am daisy the pig</div>
</body></html>
        """
        rules_str = """\
<rules xmlns="http://namespaces.plone.org/diazo" xmlns:css="http://namespaces.plone.org/diazo/css" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!--TODO: proper path -->
  <theme href="/srv/work/diazo.debugger-buildout/src/diazo/lib/diazo/tests/external_theme.html" css:if-content="body.external" />
  <rules if-content="/html/body[@id = 'theme-on']" useless="I need to be put before if-content processing">
      <replace css:content="div.cow" css:theme="div.cow" />
      <replace css:content="div.pig" css:theme="div.pig" />
      <replace css:content="div.antelope" css:theme="div.antelope" />
  </rules>
</rules>
        """
        theme_str = """\
<html><body>
  <h1>Theme</h1>
  <div class="cow">I am daisy the cow</div>
  <div class="pig">I am daisy the pig</div>
</body></html>
        """
        # Make a compiled version
        ct = diazo.compiler.compile_theme(
            rules=StringIO(rules_str),
            theme=StringIO(theme_str),
            indent=True,
            )
        print etree.tostring(ct,pretty_print=True)
        processor = etree.XSLT(ct)
        result = processor(etree.fromstring(content_str))
        print processor.error_log
        runtraces = [line.message.replace("RUNTRACE: ","<?xml version=\"1.0\"?>",1) for line in processor.error_log if line.message.startswith('RUNTRACE: ')]
        self.assertEqual(len(runtraces),1)
        runtrace = etree.fromstring(runtraces[0])
        print "----------"
        print etree.tostring(runtrace,pretty_print=True)

def test_suite():
    return unittest.defaultTestLoader.loadTestsFromName(__name__)
