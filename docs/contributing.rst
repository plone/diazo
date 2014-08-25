.. _contributing-to-this-documentation:

Contributing to this documentation
==================================

Contributing to this documentation is easy, just follow these steps*:

1. Install Sphinx_.

.. _Sphinx: http://pypi.python.org/pypi/Sphinx

2. Fork the github repository at https://github.com/plone/diazo.

   If you don't know how to do it, check `Fork a Repo <http://help.github.com/fork-a-repo/>`_
   at GitHub Help.

3. Check out the repository you just forked::

    $ git clone https://github.com/YOUR-GITHUB-USERNAME/diazo

4. Change directories to the documentation directory::

    $ cd diazo/docs

5. Make your changes. If you don't know Sphinx or reStructuredText,
   you can read about them respectively here_, `and here`_.

   To see the final result you can run::

    $ make html

.. _here: http://sphinx.pocoo.org/
.. _`and here`: http://docutils.sourceforge.net/rst.html

6. Commit your changes and push them back to your github fork::

    $ git commit -m 'Added documentation to make the world a better place'
    $ git push origin master

7. Send a `pull request <http://help.github.com/send-pull-requests/>`_
   with your changes.

   See how in `Send Pull Requests <http://help.github.com/send-pull-requests/>`_
   at GitHub Help.


Contributing to Diazo
=====================

Diazo is maintained by the Plone project. The canonical source code
repository can be found at::

    https://github.com/plone/diazo

You can follow the same
:ref:`fork & pull request <contributing-to-this-documentation>`
procedure described above to contribute to the source.

Discussion about the development of Diazo happens mainly on the
``plone-developers`` mailing list.

If you have questions as a user of Diazo, please see http://plone.org/support.

Some important ground rules:

* Please do each new features on a separate branch.
  Bugfixes can be done in the *master* branch.

* Keep the tests passing and write new tests (simply create a new directory
  in the ``tests/`` directory following the convention of the existing
  tests).
