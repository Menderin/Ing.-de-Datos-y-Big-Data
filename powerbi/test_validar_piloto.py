"""Pruebas de regresion PBIR sin Power BI, SQL Server ni internet."""
import json
import unittest
from pathlib import Path
from unittest.mock import patch

from validar_piloto import ROOT, check_report_definition, check_dax_identifiers


class PbirTests(unittest.TestCase):
    def test_rejected_dax_variable(self):
        model = {'tables': [{'measures': [{'name': 'Prueba', 'expression': 'VAR Id = 1 RETURN Id'}]}]}
        with self.assertRaisesRegex(ValueError, 'Variable Id'):
            check_dax_identifiers(model)
        model['tables'][0]['measures'][0]['expression'] = 'VAR ClienteActual = 1 RETURN ClienteActual'
        check_dax_identifiers(model)

    def setUp(self):
        self.report = ROOT / 'PilotoVentas.Report'
        self.overrides = {}
        original = Path.read_text

        def read(path, *args, **kwargs):
            return self.overrides[path] if path in self.overrides else original(path, *args, **kwargs)

        self.reader = patch.object(Path, 'read_text', read)
        self.reader.start()
        self.addCleanup(self.reader.stop)

    def change(self, relative, key, value):
        path = self.report / relative
        data = json.loads(path.read_text(encoding='utf-8'))
        data[key] = value
        self.overrides[path] = json.dumps(data)

    def test_current_report(self):
        check_report_definition(self.report)

    def test_old_content_version_is_rejected(self):
        self.change('definition/version.json', 'version', '1.0.0')
        with self.assertRaisesRegex(ValueError, 'version de contenido'):
            check_report_definition(self.report)

    def test_unknown_active_page_is_rejected(self):
        self.change('definition/pages/pages.json', 'activePageName', 'NoExiste')
        with self.assertRaisesRegex(ValueError, 'pagina activa'):
            check_report_definition(self.report)

    def test_missing_page_is_rejected(self):
        self.change('definition/pages/pages.json', 'pageOrder', ['NoExiste'])
        self.change('definition/pages/pages.json', 'activePageName', 'NoExiste')
        with self.assertRaisesRegex(ValueError, 'carpetas'):
            check_report_definition(self.report)

    def test_wrong_visual_name_is_rejected(self):
        self.change('definition/pages/V1_ResumenVentas/visuals/Kpi0/visual.json',
                    'name', 'OtroNombre')
        with self.assertRaisesRegex(ValueError, 'Identificador'):
            check_report_definition(self.report)

    def test_missing_sales_filter_is_rejected(self):
        self.change('definition/pages/V1_ResumenVentas/visuals/FiltroAnio/visual.json',
                    'filterConfig', {'filters': []})
        with self.assertRaisesRegex(ValueError, 'opciones con ventas'):
            check_report_definition(self.report)

    def test_overlap_is_rejected(self):
        self.change('definition/pages/V1_ResumenVentas/visuals/Kpi0/visual.json',
                    'position', {'x': 24, 'y': 24, 'width': 296, 'height': 88})
        with self.assertRaisesRegex(ValueError, 'solapados'):
            check_report_definition(self.report)

    def test_new_pages_are_styled(self):
        for name in ('C2_ValorClientes','C3_Recompra','C4_Geografia','C5_Canales'):
            page = json.loads((self.report/'definition/pages'/name/'page.json').read_text(encoding='utf-8'))
            self.assertEqual(page['height'], 1024)
            for path in (self.report/'definition/pages'/name/'visuals').glob('*/visual.json'):
                visual = json.loads(path.read_text(encoding='utf-8'))
                self.assertIn('border', visual['visual']['visualContainerObjects'])
                self.assertIn('background', visual['visual']['visualContainerObjects'])

    def test_c4_does_not_repeat_sales_page(self):
        for path in (self.report/'definition/pages/C4_Geografia/visuals').glob('*/visual.json'):
            visual = json.loads(path.read_text(encoding='utf-8'))
            for role in visual['visual']['query']['queryState'].values():
                for projection in role['projections']:
                    kind, field = next(iter(projection['field'].items()))
                    self.assertNotEqual(field['Expression']['SourceRef']['Entity'], 'DimTerritory')
                    self.assertNotIn(field['Property'], ('Ventas Netas','GrossMargin','Year','MonthName'))

    def test_production_pages_are_distinct(self):
        names = ('P1_PanoramaProduccion','P2_Calidad','P3_Inventario','P4_CentrosTrabajo','P5_Catalogo')
        for name in names:
            paths = list((self.report/'definition/pages'/name/'visuals').glob('*/visual.json'))
            self.assertEqual(len(paths), 12)
            for path in paths:
                visual = json.loads(path.read_text(encoding='utf-8'))
                self.assertIn('border', visual['visual']['visualContainerObjects'])
                for role in visual['visual']['query']['queryState'].values():
                    for projection in role['projections']:
                        field = next(iter(projection['field'].values()))
                        table = field['Expression']['SourceRef']['Entity']
                        self.assertNotEqual(table, 'FactSales')
                        if name in ('P3_Inventario','P5_Catalogo'):
                            self.assertNotEqual(table, 'DimDate')
                        if name=='P5_Catalogo':
                            self.assertEqual(table, 'DimProduct')

    def test_global_reorder_and_local_detail(self):
        model = json.loads((ROOT/'PilotoVentas.SemanticModel/model.bim').read_text(encoding='utf-8'))['model']
        measures = {m['name']:m for t in model['tables'] for m in t.get('measures',[])}
        self.assertIn('REMOVEFILTERS ( DimLocation )', measures['P3 Stock Total Producto']['expression'])
        self.assertIn('NOT ISBLANK ( Existencias )', measures['P3 Bajo Reorden']['expression'])
        path = self.report/'definition/pages/P3_Inventario/visuals/Detalle/visual.json'
        detail = json.loads(path.read_text(encoding='utf-8'))
        self.assertEqual(detail['filterConfig']['filters'][0]['field']['Measure']['Property'], 'P3 Productos Con Registro')
        self.assertIn('DIVIDE', measures['P2 Tasa Descarte']['expression'])

    def test_production_date_roles(self):
        model = json.loads((ROOT/'PilotoVentas.SemanticModel/model.bim').read_text(encoding='utf-8'))['model']
        dates = {r['fromTable']:r['fromColumn'] for r in model['relationships'] if r['toTable']=='DimDate' and r['isActive']}
        self.assertEqual(dates['FactWorkOrder'], 'StartDateKey')
        self.assertEqual(dates['FactWorkOrderRouting'], 'ActualStartDateKey')
        self.assertNotIn('FactInventorySnapshot', dates)

    def visual(self, page, name):
        return json.loads((self.report/'definition/pages'/page/'visuals'/name/'visual.json').read_text(encoding='utf-8'))

    def test_production_visual_diversity(self):
        expected = {
            'P1_PanoramaProduccion': ('lineChart','columnChart'),
            'P2_Calidad': ('lineClusteredColumnComboChart','pivotTable'),
            'P3_Inventario': ('clusteredBarChart','tableEx'),
            'P4_CentrosTrabajo': ('clusteredBarChart','pivotTable'),
            'P5_Catalogo': ('columnChart','treemap'),
        }
        for page, types in expected.items():
            for index, visual_type in enumerate(types):
                self.assertEqual(self.visual(page,f'Grafico{index}')['visual']['visualType'],visual_type)

    def test_invalid_stacked_column_identifier_is_rejected(self):
        bad_visual = self.visual('P1_PanoramaProduccion','Grafico1')['visual']
        bad_visual['visualType'] = 'stackedColumnChart'
        self.change('definition/pages/P1_PanoramaProduccion/visuals/Grafico1/visual.json',
                    'visual', bad_visual)
        with self.assertRaisesRegex(ValueError, 'Tipo de visual nativo desconocido: stackedColumnChart'):
            check_report_definition(self.report)

    def test_pareto_has_separate_percentage_axis(self):
        visual = self.visual('P2_Calidad','Grafico0')['visual']
        line = visual['query']['queryState']['Y2']['projections'][0]
        self.assertEqual(line['field']['Measure']['Property'], 'P2 Descarte Acumulado Porcentaje')
        axis = visual['objects']['valueAxis'][0]['properties']
        self.assertEqual(axis['secEnd']['expr']['Literal']['Value'], '1D')
        self.assertEqual(visual['query']['sortDefinition']['sort'][0]['direction'], 'Descending')

    def test_heatmap_roles_and_color_thresholds(self):
        visual = self.visual('P2_Calidad','Grafico1')['visual']
        self.assertEqual(set(visual['query']['queryState']), {'Rows','Columns','Values'})
        field = visual['query']['queryState']['Rows']['projections'][0]['field']['Column']
        self.assertEqual(field['Property'], 'Producto')
        rules = visual['objects']['values'][1]['properties']['backColor']['solid']['color']['expr']['Conditional']['Cases']
        self.assertEqual([r['Condition']['Comparison']['Right']['Literal']['Value'] for r in rules], ['500D','100D','50D','0D'])

    def test_zero_variance_and_exact_reorder_are_not_alerts(self):
        for page in ('P3_Inventario','P4_CentrosTrabajo'):
            cells = self.visual(page,'Grafico1')['visual']['objects']['values']
            for cell in cells:
                fill = cell.get('properties',{}).get('backColor',{})
                rules = fill.get('solid',{}).get('color',{}).get('expr',{}).get('Conditional',{}).get('Cases',[])
                for rule in rules:
                    self.assertIn(rule['Condition']['Comparison']['ComparisonKind'], (1,3))

    def test_sales_pages_have_green_panels(self):
        for page in ('V1_ResumenVentas','V2_Productos','V3_Territorios','V4_Vendedores','V5_Descuentos'):
            header = self.visual(page,'Cabecera')['visual']['visualContainerObjects']
            self.assertEqual(header['background'][0]['properties']['color']['solid']['color']['expr']['Literal']['Value'], "'#214E3B'")

    def test_sales_drill_levels_are_in_visuals(self):
        for page, expected in [('V2_Productos',['CategoryName','SubcategoryName','Producto']),
                               ('V3_Territorios',['Group','CountryRegionCode','TerritoryName'])]:
            projections = self.visual(page,'Grafico1')['visual']['query']['queryState']['Category']['projections']
            self.assertEqual([p['field']['Column']['Property'] for p in projections],expected)
            self.assertEqual([p['active'] for p in projections],[True,False,False])

    def test_sales_donut_roles_and_waterfall(self):
        for page in ('V1_ResumenVentas','V5_Descuentos'):
            self.assertEqual(set(self.visual(page,'Grafico1')['visual']['query']['queryState']),{'Category','Y'})
        waterfall = self.visual('V5_Descuentos','Grafico0')['visual']
        self.assertEqual(waterfall['visualType'],'waterfallChart')
        self.assertEqual(waterfall['query']['queryState']['Y']['projections'][0]['field']['Measure']['Property'],'V5 Puente')
        self.assertIn('sentimentColors',waterfall['objects'])

    def test_invalid_donut_roles_are_rejected(self):
        visual = self.visual('V1_ResumenVentas','Grafico1')['visual']
        roles = visual['query']['queryState']
        roles['Legend'] = roles.pop('Category')
        roles['Values'] = roles.pop('Y')
        self.change('definition/pages/V1_ResumenVentas/visuals/Grafico1/visual.json','visual',visual)
        with self.assertRaisesRegex(ValueError,'anillo nativo requiere Category/Y'):
            check_report_definition(self.report)

    def test_sales_seller_scope_and_bridge_safety(self):
        model = json.loads((ROOT/'PilotoVentas.SemanticModel/model.bim').read_text(encoding='utf-8'))['model']
        sales = next(t for t in model['tables'] if t['name']=='FactSales')
        measures = {m['name']:m['expression'] for m in sales['measures']}
        self.assertIn('KEEPFILTERS ( DimSalesPerson[SalesPersonKey] <> 0 )',measures['V4 Ventas'])
        self.assertFalse(any('SalesQuota' in expr for name,expr in measures.items() if name.startswith('V4 ')))
        self.assertIn('IF ( [Ordenes] > 0',measures['V5 Puente'])
        self.assertIn('2, - [V5 Descuento]',measures['V5 Puente'])
        self.assertNotIn('PuenteVenta',{r['toTable'] for r in model['relationships']})

    def test_product_top_is_selection_aware_with_tie_break(self):
        model = json.loads((ROOT/'PilotoVentas.SemanticModel/model.bim').read_text(encoding='utf-8'))['model']
        measures = {m['name']:m['expression'] for t in model['tables'] for m in t.get('measures',[])}
        self.assertIn('ALLSELECTED ( DimProduct )',measures['V2 Posicion Producto'])
        self.assertIn('DimProduct[ProductKey] < ProductoActual',measures['V2 Posicion Producto'])
        self.assertIn('[V2 Posicion Producto] <= 10',measures['V2 Venta Top 10'])

    def test_treemap_groups_category_and_subcategory(self):
        roles = self.visual('P5_Catalogo','Grafico1')['visual']['query']['queryState']
        self.assertEqual(set(roles), {'Group','Details','Values'})
        self.assertEqual(roles['Group']['projections'][0]['field']['Column']['Property'], 'CategoryName')
        self.assertEqual(roles['Details']['projections'][0]['field']['Column']['Property'], 'SubcategoryName')


if __name__ == '__main__':
    unittest.main(verbosity=2)
