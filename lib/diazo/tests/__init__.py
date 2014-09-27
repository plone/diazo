def alltests():
    import unittest
    from . import (
        test_trace,
        test_wsgi,
        test_diazo,
    )
    modules = [test_trace, test_wsgi, test_diazo]
    return unittest.TestSuite([module.test_suite() for module in modules])
