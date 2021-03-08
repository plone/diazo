# -*- coding: utf-8 -*-


def alltests():
    from . import test_diazo
    from . import test_trace
    from . import test_wsgi

    import unittest
    modules = [
        test_trace,
        test_wsgi,
        test_diazo,
    ]
    return unittest.TestSuite([module.test_suite() for module in modules])
