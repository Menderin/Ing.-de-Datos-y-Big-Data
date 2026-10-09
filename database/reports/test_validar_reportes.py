"""Pruebas locales del validador, sin conexion ni cambios al DW."""
import copy
import json
import unittest
from decimal import Decimal
from pathlib import Path

from validar_reportes import ROOT, check_controls, packets


class ReportControlTests(unittest.TestCase):
    def setUp(self):
        reference = json.loads((ROOT/'powerbi'/'piloto'/'referencia_sql.json').read_text(encoding='utf-8'))
        # Las cifras de referencia se guardan como cadenas para preservar precision.
        self.r, self.p = reference['reports'],reference['pilot']
        for group in (self.r,self.p):
            for values in group.values():
                for key,value in values.items():
                    if isinstance(value,str) and value.replace('.','',1).replace('-','',1).isdigit():
                        values[key]=Decimal(value)

    def test_reference(self):
        self.assertEqual(len(check_controls(self.r,self.p)),26)

    def test_missing_report(self):
        del self.r['P3']
        with self.assertRaises(ValueError):
            check_controls(self.r,self.p)

    def test_wrong_margin(self):
        self.r['V1']['margen']+=1
        with self.assertRaises(ValueError):
            check_controls(self.r,self.p)

    def test_wrong_segments(self):
        self.r['C3']['frecuentes']+=1
        with self.assertRaises(ValueError):
            check_controls(self.r,self.p)

    def test_wrong_pilot(self):
        self.p['anio_2013']['margen']+=1
        with self.assertRaises(ValueError):
            check_controls(self.r,self.p)

    def test_packets_precision_and_duplicates(self):
        parsed=packets('REPORT|V1|{"ventas":1.123456}', 'REPORT')
        self.assertEqual(parsed['V1']['ventas'],Decimal('1.123456'))
        with self.assertRaises(ValueError):
            packets('REPORT|V1|{}\nREPORT|V1|{}','REPORT')


if __name__=='__main__':
    unittest.main(verbosity=2)
