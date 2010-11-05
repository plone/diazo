from setuptools import setup, find_packages
import os.path

setup(
    name='diazo',
    version='0.4b4',
    description='''\
Diazo implements a subset of Deliverance using a pure XSLT engine. With Diazo, you
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
    license='New BSD',
    install_requires=[
        'setuptools',
        'lxml',
        ],
    entry_points = """
        [console_scripts]
        diazocompiler = diazo.compiler:main
        diazorun = diazo.run:main
        diazopreprocessor = diazo.rules:main
        """,
    )
