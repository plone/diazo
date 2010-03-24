from setuptools import setup, find_packages
setup(
    name='xdv',
    version='0.3a2',
    description='''\
XDV implements a subset of Deliverance using a pure XSLT engine. With XDV, you
"compile" your theme and ruleset in one step, then use a superfast/simple
transform on each request thereafter. Alternatively, compile your theme during
development, check it into Subversion, and not touch XDV during deployment.''',
    long_description=open("README.txt").read(),
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
        xdvcompiler = xdv.compiler:main
        xdvrun = xdv.run:main
        """,
    )
