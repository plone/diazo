# -*- coding: utf-8 -*-


def alltests():
    from diazo.tests import test_diazo
    from diazo.tests import test_trace
    from diazo.tests import test_wsgi

    import unittest
    modules = [
        test_trace,
        test_wsgi,
        test_diazo,
    ]
    return unittest.TestSuite([module.test_suite() for module in modules])
