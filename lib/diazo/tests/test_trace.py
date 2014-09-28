from io import BytesIO
import sys
import os.path
from lxml import etree

import diazo.runtrace
import diazo.compiler
import diazo.run

try:
    import unittest2 as unittest
except ImportError:
    import unittest

if __name__ == '__main__':
    __file__ = sys.argv[0]


def testfile(filename):
    return os.path.join(os.path.abspath(os.path.dirname(__file__)),
                        'test_wsgi_files', filename)


class TestDebug(unittest.TestCase):
    rules_str = b"""\
<rules xmlns="http://namespaces.plone.org/diazo"
       xmlns:css="http://namespaces.plone.org/diazo/css"
       xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <theme css:if-content="body.external">
    <html><body>
      <h1>External Theme</h1>
      <div class="cow">I am daisy the cow</div>
      <div class="pig">I am daisy the pig</div>
    </body></html>
  </theme>
  <rules if-content="/html/body[@id = 'theme-on']"
         useless="I need to be put before if-content processing">
      <replace css:content="div.bovine"
               css:theme="div.cow"
               css:if-content="body.female" />
      <replace css:content="div.bovine"
               css:theme="div.bull"
               css:if-content="body.male" />
      <replace css:content="div.pig" css:theme="div.pig" />
      <replace css:content="div.antelope" css:theme="div.antelope" />
      <replace content='//*[@id="some_other_node_but_weird_quoting"]'
               css:theme-children='#alpha' />
      <replace css:content="div.iguana" css:theme="div.bull"
               css:if-not-content="body.male" />
  </rules>
</rules>
    """
    theme_str = b"""\
<html><head>
  <meta http-equiv="content-type"
        content="text/html; charset=utf-8; i-am-not-a-diazo-rule" />
</head><body>
  <h1>Provided Theme</h1>
  <div class="cow">I am a template cow</div>
  <div class="bull">I am a template bull</div>
  <div class="pig">I am daisy the pig</div>
</body></html>
    """

    def compile(self):
        # Compile default rule and themes
        ct = diazo.compiler.compile_theme(
            rules=BytesIO(self.rules_str),
            theme=BytesIO(self.theme_str),
            indent=True,
            runtrace=True,
        )
        return etree.XSLT(ct)

    def test_internal(self):
        processor = self.compile()
        processor(etree.fromstring("""\
<html><body id="theme-on" class="male">
  <h1>Content</h1>
  <div class="bovine" id="#cow-daisy">I am frank the bull</div>
  <div class="pig" id="#pig-george">I am daisy the pig</div>
</body></html>
        """))
        runtrace_doc = diazo.runtrace.generate_runtrace(
            rules=BytesIO(self.rules_str),
            error_log=processor.error_log,
        )
        self.assertXPath(runtrace_doc, "/d:rules/d:theme/@runtrace-if-content",
                         "false")
        self.assertXPath(runtrace_doc, "/d:rules/d:rules/@runtrace-if-content",
                         "true")
        # <replace css:content="div.bovine"
        #          css:theme="div.cow"
        #          css:if-content="body.female" />
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[1]/@runtrace-if-content",
                         "false")
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[1]/@runtrace-content",
                         "1")
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[1]/@runtrace-theme", "1")
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[1]/@runtrace-merged-condition",
            "false")
        # <replace css:content="div.bovine"
        #          css:theme="div.bull"
        #          css:if-content="body.male" />
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[2]/@runtrace-if-content",
                         "true")
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[2]/@runtrace-content",
                         "1")
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[2]/@runtrace-theme", "1")
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[2]/@runtrace-merged-condition",
            "true")
        # <replace css:content="div.pig" css:theme="div.pig" />
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[3]/@runtrace-content",
                         "1")
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[3]/@runtrace-merged-condition",
            "true")
        # <replace css:content="div.antelope" css:theme="div.antelope" />
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[4]/@runtrace-content",
                         "0")
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[4]/@runtrace-merged-condition",
            "true")
        # <replace css:content="div.iguana" css:theme="div.bull"
        #          css:if-not-content="body.male" />
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[6]/@runtrace-if-not-content",
            "false")
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[6]/@runtrace-merged-condition",
            "false")

    def test_external(self):
        processor = self.compile()
        processor(etree.fromstring("""\
<html><body id="theme-on" class="female external">
  <h1>Content</h1>
  <div class="bovine" id="#cow-daisy">I am daisy the cow</div>
  <div class="pig" id="#pig-george">I am daisy the pig</div>
</body></html>
        """))
        runtrace_doc = diazo.runtrace.generate_runtrace(
            rules=BytesIO(self.rules_str),
            error_log=processor.error_log,
        )
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:theme/@runtrace-if-content", "true")
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/@runtrace-if-content", "true")
        # <replace css:content="div.bovine"
        #          css:theme="div.cow"
        #          css:if-content="body.female" />
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[1]/@runtrace-if-content",
                         "true")
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[1]/@runtrace-content",
                         "1")
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[1]/@runtrace-theme", "1")
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[1]/@runtrace-merged-condition", "true")
        # <replace css:content="div.bovine"
        #          css:theme="div.bull"
        #          css:if-content="body.male" />
        # The external theme only has the cow slot
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[2]/@runtrace-if-content",
                         "false")
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[2]/@runtrace-content",
                         "1")
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[2]/@runtrace-theme", "0")
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[2]/@runtrace-merged-condition",
            "false")
        # <replace css:content="div.pig" css:theme="div.pig" />
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[3]/@runtrace-content",
                         "1")
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[3]/@runtrace-merged-condition", "true")
        # <replace css:content="div.antelope" css:theme="div.antelope" />
        self.assertXPath(runtrace_doc,
                         "/d:rules/d:rules/d:replace[4]/@runtrace-content",
                         "0")
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[4]/@runtrace-merged-condition", "true")
        # <replace css:content="div.iguana" css:theme="div.bull"
        #          css:if-not-content="body.male" />
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[6]/@runtrace-if-not-content",
            "true")
        self.assertXPath(
            runtrace_doc,
            "/d:rules/d:rules/d:replace[6]/@runtrace-merged-condition",
            "true")

    def test_htmlformat(self):
        html_string = etree.tostring(
            diazo.runtrace.runtrace_to_html(etree.fromstring("""\
<rules xmlns="http://namespaces.plone.org/diazo"
       xmlns:css="http://namespaces.plone.org/diazo/css"
       xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
       css:if-content="#visual-portal-wrapper"
       xml:id="r0" runtrace-if-content="true">

    <theme href="index.html" xml:id="r1"/>
    <notheme if-path="presentation_view" xml:id="r2"/>
    <notheme if-path="source_editor.htm" xml:id="r3"/>
    <rules xml:id="r4">
        <!-- Rules, lots of rules -->
        <copy xml:id="r5" content="//a" theme="//a" runtrace-content="0"
              runtrace-theme="0" />
        <copy xml:id="r6" content="//a" theme="//b" runtrace-content="1"
              runtrace-theme="0" />
        <copy xml:id="r7" content="//b" theme="//b" runtrace-content="1"
              runtrace-theme="1" />
        <copy xml:id="r8" content="//b" theme="//c" runtrace-content="1"
              runtrace-theme="2" />
    </rules>
</rules>
        """)))
        # First rule has an if-content condition
        self.assertIn(
            b"""<pre class="runtrace"><span class="node match" """
            b"""title="Matches: if-content:true ">&lt;rules""", html_string)
        # HTML comments are included and escaped
        self.assertIn(b"""&lt;!-- Rules, lots of rules --&gt;""", html_string)
        # Rules tag has children
        self.assertIn(b"""<span class="node unrelated">&lt;rules """
                      b"""<span class="attr">xml:id="r4"</span>&gt;</span>""",
                      html_string)
        # Theme tag has no conditions, is a singleton
        self.assertIn(b"""<span class="node unrelated">&lt;theme <span """
                      b"""class="attr">href="index.html"</span> <span """
                      b"""class="attr">xml:id="r1"</span>/&gt;</span>""",
                      html_string)
        # Whitespace is preserved
        self.assertIn(b"""xml:id=\"r4\"</span>&gt;</span>\n        <span """
                      b"""class="comment">&lt;!-- Rules, lots of rules """
                      b"""--&gt;</span>""", html_string)
        # Neither theme or content matched
        self.assertIn(b"""<span class="node no-match" title="Matches: """
                      b"""content:0 theme:0 ">&lt;copy <span class="attr">"""
                      b"""xml:id="r5"</span>""", html_string)
        # Just content matched, still not good enough
        self.assertIn(b"""<span class="node no-match" title="Matches: """
                      b"""content:1 theme:0 ">&lt;copy <span class="attr">"""
                      b"""xml:id="r6"</span>""", html_string)
        # Full match
        self.assertIn(b"""<span class="node match" title="Matches: """
                      b"""content:1 theme:1 ">&lt;copy <span class="attr">"""
                      b"""xml:id="r7"</span>""", html_string)
        # More than one match still fine
        self.assertIn(b"""<span class="node match" title="Matches: """
                      b"""content:1 theme:2 ">&lt;copy <span class="attr">"""
                      b"""xml:id="r8"</span>""", html_string)

    def assertXPath(self, doc, xpath, expected):
        self.assertEqual(
            doc.xpath(
                xpath,
                namespaces=(dict(d="http://namespaces.plone.org/diazo")))[0],
            expected
        )


def test_suite():
    return unittest.defaultTestLoader.loadTestsFromName(__name__)
