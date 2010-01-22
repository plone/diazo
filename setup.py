from setuptools import setup, find_packages
setup(
    name='xdv',
    version='0.3a1',
    description='''\
xdv implements a subset of Deliverance using a pure XSLT engine. With xdv, you
"compile" your theme and ruleset in one step, then use a superfast/simple
transform on each request thereafter. Alternatively, compile your theme during
development, check it into Subversion, and not touch xdv during deployment.''',
    packages=find_packages('lib'),
    package_dir = {'':'lib'},
    include_package_data=True,
    zip_safe=False,
    author='Laurence Rowe',
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
