from setuptools import setup, find_packages
import os.path
import sys

extras_require = {
    'wsgi': ['repoze.xmliter>=0.6', 'WebOb>=1.4'],
    'test': [
        'formencode',
        'repoze.xmliter>=0.6',
        'WebOb>=1.4',
    ]}

if sys.version_info < (2, 7):
    extras_require['test'].append('unittest2')

readme = open("README.rst").read()
changes = open(os.path.join("docs", "CHANGES.txt")).read()
long_desc = readme + '\n\n' + changes

setup(
    name='diazo',
    version='666.1.2.dev0',
    description='''Diazo implements a Deliverance like language using a pure
        XSLT engine. With Diazo, you "compile" your theme and ruleset in one
        step, then use a superfast/simple transform on each request thereafter.
        Alternatively, compile your theme during development, check it into
        version control, and not touch Diazo during deployment.''',
    keywords='web theming',
    long_description=long_desc,
    packages=find_packages('lib'),
    package_dir={'': 'lib'},
    include_package_data=True,
    zip_safe=False,
    author='Paul Everitt, Laurence Rowe and Martin Aspeli.',
    author_email='laurence@lrowe.co.uk',
    url="http://diazo.org",
    license='New BSD',
    classifiers=[
        "Development Status :: 6 - Mature",
        "Topic :: Internet :: WWW/HTTP",
        "Topic :: Internet :: WWW/HTTP :: WSGI",
        "Topic :: Internet :: WWW/HTTP :: WSGI :: Middleware",
        "Topic :: Text Processing :: Markup :: XML",
        ],
    install_requires=[
        'setuptools',
        'lxml',
        'experimental.cssselect',
        'future',
        'six'],
    extras_require=extras_require,
    test_suite="diazo.tests.alltests",
    tests_require=extras_require['test'],
    entry_points="""
        [console_scripts]
        diazocompiler = diazo.compiler:main
        diazorun = diazo.run:main
        diazopreprocessor = diazo.rules:main

        [paste.filter_app_factory]
        xslt = diazo.wsgi:XSLTMiddleware
        main = diazo.wsgi:DiazoMiddleware
        """,
)
