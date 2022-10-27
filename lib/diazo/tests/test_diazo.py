# -*- coding: utf-8 -*-

from __future__ import print_function

from builtins import str
from diazo.utils import quote_param
from io import BytesIO
from io import open
from io import StringIO
from lxml import etree

import diazo.compiler
import diazo.run
import difflib
import os
import pkg_resources
import six
import sys
import unittest


#
# Simple test runner for validating different diazo scenarios
#

try:
    import configparser
except ImportError:
    import ConfigParser as configparser


if __name__ == '__main__':
    __file__ = sys.argv[0]


defaultsfn = pkg_resources.resource_filename(
    'diazo.tests',
    'default-options.cfg',
)


def text_compare(t1, t2):
    # Copied from formencode.doctest_xml_compare.text_compare 2.0.1.
    # See note in xml_compare below.
    if not t1 and not t2:
        return True
    if t1 == '*' or t2 == '*':
        return True
    return (t1 or '').strip() == (t2 or '').strip()


def xml_compare(x1, x2):
    """Compare two xml items.

    Copied from formencode.doctest_xml_compare.xml_compare 2.0.1,
    without the (unused by us) optional 'reporter' argument.

    License: MIT

    Copyright (c) 2015 Ian Bicking and FormEncode Contributors

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
    """
    if x1.tag != x2.tag:
        return False
    for name, value in six.iteritems(x1.attrib):
        if x2.attrib.get(name) != value:
            return False
    for name in x2.attrib:
        if name not in x1.attrib:
            return False
    if not text_compare(x1.text, x2.text):
        return False
    if not text_compare(x1.tail, x2.tail):
        return False
    cl1 = list(x1)
    cl2 = list(x2)
    if len(cl1) != len(cl2):
        return False
    i = 0
    for c1, c2 in zip(cl1, cl2):
        i += 1
        if not xml_compare(c1, c2):
            return False
    return True


class DiazoTestCase(unittest.TestCase):

    writefiles = os.environ.get('DiazoTESTS_WRITE_FILES', False)
    warnings = os.environ.get(
        'DiazoTESTS_WARN',
        '1',
    ).lower() not in ('0', 'false', 'off')

    testdir = os.path.realpath(__file__)

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

            test_cls = type(
                '{prefix:s}-{name:s}'.format(
                    prefix=prefix,
                    name=name,
                ),
                (DiazoTestCase,),
                dict(testdir=path),
            )
            suite.addTest(unittest.makeSuite(test_cls))
        return suite

    def testAll(self):
        self.errors = BytesIO()
        config = configparser.ConfigParser()
        config.read([defaultsfn, os.path.join(self.testdir, 'options.cfg')])

        themefn = None
        if config.get('diazotest', 'theme'):
            themefn = os.path.join(
                self.testdir,
                config.get('diazotest', 'theme'),
            )
        contentfn = os.path.join(self.testdir, 'content.html')
        rulesfn = os.path.join(self.testdir, 'rules.xml')
        xpathsfn = os.path.join(self.testdir, 'xpaths.txt')
        xslfn = os.path.join(self.testdir, 'compiled.xsl')
        outputfn = os.path.join(self.testdir, 'output.html')

        xsl_params = {}
        extra_params = config.get('diazotest', 'extra-params')
        if extra_params:
            for token in extra_params.split(' '):
                token_split = token.split(':')
                xsl_params[token_split[0]] = len(token_split) > 1 and \
                    token_split[1] or None

        if not os.path.exists(rulesfn):
            return

        contentdoc = etree.parse(
            source=contentfn,
            base_url=contentfn,
            parser=etree.HTMLParser(),
        )

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
                    print('WARNING:', 'compiled.xsl has CHANGED')
                    for line in difflib.unified_diff(
                        old.split(u'\n'),
                        new.split(u'\n'),
                        xslfn,
                        'now',
                    ):
                        print(line)

        # Write the compiled xsl out to catch unexpected changes
        if self.writefiles:
            with open(xslfn, 'w') as f:
                f.write(cts)

        # Apply the compiled version, then test against desired output
        theme_parser.resolvers.add(diazo.run.RunResolver(self.testdir))
        processor = etree.XSLT(ct)
        params = {}
        params['path'] = "'{path:s}'".format(
            path=config.get('diazotest', 'path'),
        )

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
            file=StringIO(self.themed_string),
            parser=etree.HTMLParser(),
        )

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
                    assert self.themed_content.xpath(this_xpath), '{key:s}: {value:s}'.format(  # NOQA: E501
                        key=xpathsfn,
                        value=this_xpath,
                    )

        # Compare to previous version
        if os.path.exists(outputfn):
            with open(outputfn, 'rb') as f:
                old = f.read()
            new = self.themed_string
            if not xml_compare(
                etree.fromstring(old.strip()),
                etree.fromstring(new.strip()),
            ):
                # if self.writefiles:
                #    open(outputfn + '.old', 'w').write(old)
                for line in difflib.unified_diff(
                    old.split(u'\n'),
                    new.split(u'\n'),
                    outputfn,
                    'now',
                ):
                    print(line)
                assert old == new, 'output.html has CHANGED'

        # Write out the result to catch unexpected changes
        if self.writefiles:
            with open(outputfn, 'w') as f:
                f.write(self.themed_string)


def test_suite():
    suite = unittest.TestSuite()
    tests_dir = os.path.dirname(__file__)
    suite.addTest(DiazoTestCase.suiteForParent(tests_dir, 'Test'))
    recipes_dir = os.path.join(
        tests_dir,
        "../../..",
        "docs/recipes",
    )
    if os.path.exists(os.path.join(recipes_dir, 'diazo-tests-marker.txt')):
        # Could still be a 'System' package.
        suite.addTest(DiazoTestCase.suiteForParent(recipes_dir, 'Recipe'))
    return suite
