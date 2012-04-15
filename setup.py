from setuptools import setup, find_packages
import os.path

setup(
    name='diazo',
    version='1.0',
    description='''\
Diazo implements a Deliverance like language using a pure XSLT engine. With Diazo, you
"compile" your theme and ruleset in one step, then use a superfast/simple
transform on each request thereafter. Alternatively, compile your theme during
development, check it into Subversion, and not touch Diazo during deployment.''',
    long_description=open("README.txt").read() + "\n\n" +
                     open(os.path.join("docs", "CHANGES.txt")).read(),
    packages=find_packages('lib'),
    package_dir = {'':'lib'},
    include_package_data=True,
    zip_safe=False,
    author='Paul Everitt, Laurence Rowe and Martin Aspeli.',
    author_email='laurence@lrowe.co.uk',
    url="http://diazo.org",
    license='New BSD',
    install_requires=[
        'setuptools',
        'lxml',
        'experimental.cssselect',
        ],
    extras_require={
        'wsgi': ['repoze.xmliter>=0.3', 'WebOb'],
        'test': ['repoze.xmliter>=0.3', 'WebOb', 'unittest2'],
        },
    entry_points = """
        [console_scripts]
        diazocompiler = diazo.compiler:main
        diazorun = diazo.run:main
        diazopreprocessor = diazo.rules:main
        
        [paste.filter_app_factory]
        xslt = diazo.wsgi:XSLTMiddleware
        main = diazo.wsgi:DiazoMiddleware
        """,
    )
