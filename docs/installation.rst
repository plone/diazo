Installation
============

To install Diazo, you should install the ``diazo`` Python distribution.

  **Note:** The Diazo package is only required to get the Diazo compiler and
  development tools. If you deploy your Diazo theme into a web server, you
  do not need the ``diazo`` distribution on that server.

You can install the ``diazo`` distribution using ``easy_install``, ``pip`` or
``zc.buildout``. For example, using ``easy_install`` (ideally in a
``virtualenv``)::

    $ easy_install -U diazo

If using ``zc.buildout``, you can use the following ``buildout.cfg`` as a
starting point. This will ensure that the console scripts are installed,
which is important if you need to execute the Diazo compiler manually::

    [buildout]
    parts =
        diazo

    [diazo]
    recipe = zc.recipe.egg
    eggs = diazo

Note that ``lxml`` is a dependency of ``diazo``, so you may need to install
the libxml2 and libxslt development packages in order for it to build. On
Debian/Ubuntu you can run::

    $ sudo apt-get install build-essential python2.6-dev libxslt1-dev

On some operating systems, notably Mac OS X, CentOS and other RedHat-based
Linux distributions, installing a "good" ``lxml`` egg can be problematic,
due to a mismatch in the operating system versions of the ``libxml2`` and
``libxslt`` libraries that ``lxml`` uses. To get around that, you can
compile a static ``lxml`` egg using the following buildout recipe::

    [buildout]
    # lxml should be first in the parts list
    parts =
        lxml
        diazo

    [lxml]
    recipe = z3c.recipe.staticlxml
    egg = lxml

    [diazo]
    recipe = zc.recipe.egg
    eggs = diazo

Once installed, you should find ``diazocompiler`` and ``diazorun`` in your
``bin`` directory.

If you want to use the WSGI middleware filter, you should use the ``[wsgi]``
extra when installing the Diazo egg. See :doc:`quickstart` for an example.