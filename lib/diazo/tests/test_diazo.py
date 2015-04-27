from __future__ import print_function
#
# Simple test runner for validating different diazo scenarios
#

from lxml import etree
import os
import sys
import difflib
from io import BytesIO, StringIO, open
import unittest
try:
    import configparser
except ImportError:
    import ConfigParser as configparser
import pkg_resources

import diazo.compiler
import diazo.run

from diazo.utils import quote_param
from formencode.doctest_xml_compare import xml_compare
from future.builtins import str


if __name__ == '__main__':
    __file__ = sys.argv[0]

defaultsfn = pkg_resources.resource_filename('diazo.tests',
                                             'default-options.cfg')


class DiazoTestCase(unittest.TestCase):

    writefiles = os.environ.get('DiazoTESTS_WRITE_FILES', False)
    warnings = os.environ.get(
        'DiazoTESTS_WARN', "1").lower() not in ('0', 'false', 'off')

    testdir = None  # override

    @classmethod
    def suiteForParent(cls, parent, prefix):
        """Return a suite of diazo tests, one for each directory in parent.
        """
        suite = unittest.TestSuite()
        for name in os.listdir(parent):
            if name.startswith('.'):
                continue
            path = os.path.join(parent, name)
            if not os.path.isdir(path):
                continue

            contentpath = os.path.join(path, 'content.html')
            if not os.path.isfile(contentpath):
                continue

            test_cls = type('%s-%s' % (prefix, name), (DiazoTestCase,),
                            dict(testdir=path))
            suite.addTest(unittest.makeSuite(test_cls))
        return suite

    def testAll(self):
        self.errors = BytesIO()
        config = configparser.ConfigParser()
        config.read([defaultsfn, os.path.join(self.testdir, "options.cfg")])

        themefn = None
        if config.get('diazotest', 'theme'):
            themefn = os.path.join(self.testdir, config.get('diazotest',
                                                            'theme'))
        contentfn = os.path.join(self.testdir, "content.html")
        rulesfn = os.path.join(self.testdir, "rules.xml")
        xpathsfn = os.path.join(self.testdir, "xpaths.txt")
        xslfn = os.path.join(self.testdir, "compiled.xsl")
        outputfn = os.path.join(self.testdir, "output.html")

        xsl_params = {}
        extra_params = config.get('diazotest', 'extra-params')
        if extra_params:
            for token in extra_params.split(' '):
                token_split = token.split(':')
                xsl_params[token_split[0]] = len(token_split) > 1 and \
                    token_split[1] or None

        if not os.path.exists(rulesfn):
            return

        contentdoc = etree.parse(source=contentfn, base_url=contentfn,
                                 parser=etree.HTMLParser())

        # Make a compiled version
        theme_parser = etree.HTMLParser()
        ct = diazo.compiler.compile_theme(
            rules=rulesfn,
            theme=themefn,
            parser=theme_parser,
            absolute_prefix=config.get('diazotest', 'absolute-prefix'),
            indent=config.getboolean('diazotest', 'pretty-print'),
            xsl_params=xsl_params,
        )

        # Serialize / parse the theme - this can catch problems with escaping.
        cts = etree.tostring(ct, encoding='unicode')
        parser = etree.XMLParser()
        etree.fromstring(cts, parser=parser)

        # Compare to previous version
        if os.path.exists(xslfn):
            with open(xslfn) as f:
                old = f.read()
            new = cts
            if old != new:
                if self.writefiles:
                    with open(xslfn + '.old', 'w') as f:
                        f.write(old)
                if self.warnings:
                    print("WARNING:", "compiled.xsl has CHANGED")
                    for line in difflib.unified_diff(old.split(u'\n'),
                                                     new.split(u'\n'),
                                                     xslfn, 'now'):
                        print(line)

        # Write the compiled xsl out to catch unexpected changes
        if self.writefiles:
            with open(xslfn, 'w') as f:
                f.write(cts)

        # Apply the compiled version, then test against desired output
        theme_parser.resolvers.add(diazo.run.RunResolver(self.testdir))
        processor = etree.XSLT(ct)
        params = {}
        params['path'] = "'%s'" % config.get('diazotest', 'path')

        for key in xsl_params:
            try:
                params[key] = quote_param(config.get('diazotest', key))
            except configparser.NoOptionError:
                pass

        result = processor(contentdoc, **params)

        # Read the whole thing to strip off xhtml namespace.
        # If we had xslt 2.0 then we could use xpath-default-namespace.
        self.themed_string = str(result)
        self.themed_content = etree.ElementTree(
            file=StringIO(self.themed_string), parser=etree.HTMLParser())

        # remove the extra meta content type

        metas = self.themed_content.xpath(
            "/html/head/meta[@http-equiv='Content-Type']")
        if metas:
            meta = metas[0]
            meta.getparent().remove(meta)

        if os.path.exists(xpathsfn):
            with open(xpathsfn) as f:
                for xpath in f.readlines():
                    # Read the XPaths from the file, skipping blank lines and
                    # comments
                    this_xpath = xpath.strip()
                    if not this_xpath or this_xpath[0] == '#':
                        continue
                    assert self.themed_content.xpath(this_xpath), "%s: %s" % (
                        xpathsfn, this_xpath)

        # Compare to previous version
        if os.path.exists(outputfn):
            with open(outputfn) as f:
                old = f.read()
            new = self.themed_string
            if not xml_compare(
                    etree.fromstring(old.strip()),
                    etree.fromstring(new.strip())):
                # if self.writefiles:
                #    open(outputfn + '.old', 'w').write(old)
                for line in difflib.unified_diff(old.split(u'\n'),
                                                 new.split(u'\n'),
                                                 outputfn, 'now'):
                    print(line)
                assert old == new, "output.html has CHANGED"

        # Write out the result to catch unexpected changes
        if self.writefiles:
            with open(outputfn, 'w') as f:
                f.write(self.themed_string)


def test_suite():
    suite = unittest.TestSuite()
    dist = pkg_resources.get_distribution('diazo')
    tests_dir = os.path.join(dist.location, 'diazo', 'tests')
    suite.addTest(DiazoTestCase.suiteForParent(tests_dir, 'Test'))
    if dist.precedence == pkg_resources.DEVELOP_DIST:
        recipes_dir = os.path.join(os.path.dirname(dist.location),
                                   'docs', 'recipes')
        if os.path.exists(os.path.join(recipes_dir, 'diazo-tests-marker.txt')):
            # Could still be a 'System' package.
            suite.addTest(DiazoTestCase.suiteForParent(recipes_dir, 'Recipe'))
    return suite
