from setuptools import setup, find_packages
setup(
    name='xdv',
    version='0.3',
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
