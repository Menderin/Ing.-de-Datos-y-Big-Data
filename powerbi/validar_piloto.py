"""Comprueba referencias/layout del PBIP. --schemas consulta esquemas Microsoft.

No abre Power BI ni ejecuta DAX; esas comprobaciones siguen pendientes en Desktop.
El chequeo de esquemas implementa el subconjunto de Draft 7 usado por este piloto,
no pretende ser una biblioteca general de JSON Schema.
"""
import argparse
import json
import re
from pathlib import Path
from urllib.parse import urldefrag, urljoin, urlparse
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parent / 'piloto'
CACHE = {}

# Identificadores nativos usados por este proyecto. columnChart corresponde a
# columnas apiladas; stackedColumnChart no existe en el registro de Desktop.
# El esquema JSON permite cualquier cadena y no comprueba este registro.
NATIVE_VISUAL_TYPES = {
    'barChart', 'columnChart', 'clusteredBarChart', 'clusteredColumnChart',
    'card', 'slicer', 'lineChart', 'lineClusteredColumnComboChart',
    'donutChart', 'scatterChart', 'pivotTable', 'tableEx', 'treemap', 'waterfallChart',
}


def document(url):
    if urlparse(url).hostname != 'developer.microsoft.com':
        raise ValueError('Referencia de esquema fuera de Microsoft: '+url)
    if url not in CACHE:
        with urlopen(url, timeout=30) as response:
            CACHE[url] = json.load(response)
    return CACHE[url]


def schema_check(value, schema, base, location='$'):
    if isinstance(schema, bool):
        if not schema:
            raise ValueError(location+': valor prohibido')
        return
    if '$ref' in schema:
        url, fragment = urldefrag(urljoin(base, schema['$ref']))
        target = document(url)
        for part in fragment.lstrip('/').split('/') if fragment else []:
            target = target[part.replace('~1','/').replace('~0','~')]
        schema_check(value, target, url, location)
        return
    for child in schema.get('allOf', []):
        schema_check(value, child, base, location)
    for keyword in ('anyOf', 'oneOf'):
        if keyword in schema:
            successes = 0
            for child in schema[keyword]:
                try:
                    schema_check(value, child, base, location)
                    successes += 1
                except ValueError:
                    pass
            if successes == 0 or (keyword == 'oneOf' and successes != 1):
                raise ValueError(location+': no cumple '+keyword)
    if 'not' in schema:
        try:
            schema_check(value, schema['not'], base, location)
        except ValueError:
            pass
        else:
            raise ValueError(location+': coincide con esquema prohibido')
    if 'if' in schema:
        try:
            schema_check(value, schema['if'], base, location)
            branch = 'then'
        except ValueError:
            branch = 'else'
        if branch in schema:
            schema_check(value, schema[branch], base, location)
    checks = {'object': isinstance(value, dict), 'array': isinstance(value, list),
              'string': isinstance(value, str), 'boolean': isinstance(value, bool),
              'number': isinstance(value, (int,float)) and not isinstance(value,bool),
              'integer': isinstance(value,int) and not isinstance(value,bool), 'null': value is None}
    if 'type' in schema:
        types = schema['type'] if isinstance(schema['type'],list) else [schema['type']]
        if not any(checks[t] for t in types):
            raise ValueError(location+': tipo incorrecto')
    if 'const' in schema and value != schema['const']:
        raise ValueError(location+': constante incorrecta')
    if 'enum' in schema and value not in schema['enum']:
        raise ValueError(location+': valor no permitido')
    if isinstance(value,dict):
        for key in schema.get('required',[]):
            if key not in value:
                raise ValueError(location+': falta '+key)
        properties = schema.get('properties',{})
        patterns = schema.get('patternProperties',{})
        for key, item in value.items():
            matched = False
            if key in properties:
                schema_check(item,properties[key],base,location+'.'+key)
                matched = True
            for pattern, rule in patterns.items():
                if re.search(pattern,key):
                    schema_check(item,rule,base,location+'.'+key)
                    matched = True
            if not matched:
                schema_check(item,schema.get('additionalProperties',True),base,location+'.'+key)
    if isinstance(value,list):
        if len(value)<schema.get('minItems',0) or len(value)>schema.get('maxItems',float('inf')):
            raise ValueError(location+': longitud de lista incorrecta')
        if schema.get('uniqueItems') and len({json.dumps(x,sort_keys=True) for x in value})!=len(value):
            raise ValueError(location+': elementos duplicados')
        for index, item in enumerate(value):
            rule = schema.get('items',True)
            if isinstance(rule,list):
                rule = rule[index] if index<len(rule) else schema.get('additionalItems',True)
            schema_check(item,rule,base,location+f'[{index}]')
    if isinstance(value,str):
        if len(value)<schema.get('minLength',0) or len(value)>schema.get('maxLength',float('inf')):
            raise ValueError(location+': longitud de texto incorrecta')
        if 'pattern' in schema and not re.search(schema['pattern'],value):
            raise ValueError(location+': patron incorrecto')
    if checks['number']:
        if value<schema.get('minimum',float('-inf')) or value>schema.get('maximum',float('inf')):
            raise ValueError(location+': fuera de rango')


def check_report_definition(report):
    """Contrato del piloto PBIR; no sustituye abrir el reporte en Desktop.

    La version del contenido no es la version 1.0.0 de su esquema JSON.
    El esquema acepta cadenas de version sin asegurar compatibilidad Desktop.
    """
    definition = report / 'definition'

    def read(path):
        return json.loads(path.read_text(encoding='utf-8'))

    version = read(definition / 'version.json')
    if version.get('version') != '2.0.0':
        raise ValueError('El piloto PBIR requiere version de contenido 2.0.0 en '
                         'definition/version.json; no confundir con el esquema 1.0.0.')
    if not version.get('$schema', '').endswith('/versionMetadata/1.0.0/schema.json'):
        raise ValueError('Falta el esquema de versionMetadata esperado.')
    pages = read(definition / 'pages' / 'pages.json')
    order = pages.get('pageOrder', [])
    if not order or len(order) != len(set(order)):
        raise ValueError('La lista de paginas esta vacia o tiene duplicados.')
    if pages.get('activePageName') not in order:
        raise ValueError('La pagina activa no pertenece a pageOrder.')
    folders = {p.name for p in (definition / 'pages').iterdir() if p.is_dir()}
    if folders != set(order):
        raise ValueError('pageOrder no coincide con las carpetas de paginas.')
    for name in order:
        page = read(definition / 'pages' / name / 'page.json')
        if page.get('name') != name:
            raise ValueError('El nombre de pagina no coincide con su carpeta: '+name)
        visual_names = set()
        rectangles = []
        for folder in (definition / 'pages' / name / 'visuals').iterdir():
            if not folder.is_dir():
                continue
            visual = read(folder / 'visual.json')
            if visual.get('name') != folder.name or visual['name'] in visual_names:
                raise ValueError('Identificador de visual inconsistente: '+folder.name)
            visual_names.add(visual['name'])
            pos = visual['position']
            for other, previous in rectangles:
                overlaps = (pos['x'] < previous['x'] + previous['width'] and
                            previous['x'] < pos['x'] + pos['width'] and
                            pos['y'] < previous['y'] + previous['height'] and
                            previous['y'] < pos['y'] + pos['height'])
                if overlaps:
                    raise ValueError('Visuales solapados: '+other+' / '+visual['name'])
            rectangles.append((visual['name'], pos))
            config = visual['visual']
            if config.get('visualType') == 'donutChart':
                roles = config.get('query', {}).get('queryState', {})
                if not {'Category', 'Y'}.issubset(roles) or {'Legend', 'Values'} & set(roles):
                    raise ValueError('El anillo nativo requiere Category/Y: '+name+'/'+folder.name)
            if config.get('visualType') not in NATIVE_VISUAL_TYPES:
                raise ValueError('Tipo de visual nativo desconocido: '+str(config.get('visualType'))+
                                 ' en '+name+'/'+folder.name)
            if folder.name.startswith('Kpi'):
                props = config['objects']['labels'][0]['properties']
                if props['labelDisplayUnits']['expr']['Literal']['Value'] != '1D':
                    raise ValueError('Una tarjeta vuelve a abreviar importes: '+folder.name)
                if pos['width'] < 280:
                    raise ValueError('Tarjeta demasiado estrecha: '+folder.name)
            if folder.name.startswith('Filtro'):
                mode = config['objects']['data'][0]['properties']['mode']
                if mode['expr']['Literal']['Value'] != "'Dropdown'":
                    raise ValueError('El filtro debe ser desplegable: '+folder.name)
                filters = visual.get('filterConfig', {}).get('filters', [])
                if name == 'V1_ResumenVentas' and not any(f.get('field', {}).get('Measure', {}).get('Property') == 'Ordenes'
                           and f.get('filter', {}).get('Where', [{}])[0].get('Condition', {}).get('Comparison', {}).get('ComparisonKind') == 1
                           for f in filters):
                    raise ValueError('Falta el filtro de opciones con ventas: '+folder.name)
        if not visual_names:
            raise ValueError('La pagina del piloto no contiene visuales: '+name)


def check_dax_identifiers(model):
    """Regresion del identificador que Desktop rechazo; no es un compilador DAX."""
    for table in model['tables']:
        for measure in table.get('measures', []):
            expression = measure['expression']
            if isinstance(expression, list):
                expression = '\n'.join(expression)
            expression = re.sub(r'"(?:[^"]|"")*"', '', expression)
            if re.search(r'\bVAR\s+Id\s*=', expression, flags=re.IGNORECASE):
                raise ValueError('Variable Id rechazada por Desktop en '+measure['name'])


def verify(schemas=False):
    pbip = json.loads((ROOT/'PilotoVentas.pbip').read_text(encoding='utf-8'))
    report = ROOT/pbip['artifacts'][0]['report']['path']
    binding = json.loads((report/'definition.pbir').read_text(encoding='utf-8'))
    check_report_definition(report)
    model_path = (report/binding['datasetReference']['byPath']['path']).resolve()
    assert model_path.is_relative_to(ROOT.resolve())
    model = json.loads((model_path/'model.bim').read_text(encoding='utf-8'))['model']
    check_dax_identifiers(model)
    tables = {t['name']:t for t in model['tables']}
    assert set(tables)=={'DimDate','DimTerritory','DimCustomer','FactSales','DimProduct',
        'DimLocation','DimScrapReason','FactWorkOrder','FactWorkOrderRouting','FactInventorySnapshot',
        'DimSalesPerson','DimSpecialOffer','PuenteVenta'}
    columns = {name:{c['name'] for c in t['columns']} for name,t in tables.items()}
    measures = {name:{m['name'] for m in t.get('measures',[])} for name,t in tables.items()}
    for table in tables.values():
        assert len({m['name'] for m in table.get('measures',[])}) == len(table.get('measures',[]))
    assert len(measures['FactSales'])==69
    assert len(model['relationships'])==14
    assert sum(len(v) for v in measures.values())==102
    assert not any(r['fromTable'].startswith('Fact') and r['toTable'].startswith('Fact')
                   for r in model['relationships'])
    assert 'CustomerKey' in columns['FactSales']
    assert any(r['fromTable']=='FactSales' and r['fromColumn']=='CustomerKey'
               and r['toTable']=='DimCustomer' and r['toColumn']=='CustomerKey'
               and r.get('isActive') for r in model['relationships'])
    assert not any({r['fromTable'],r['toTable']}=={'DimCustomer','DimTerritory'}
                   for r in model['relationships'])
    for relationship in model['relationships']:
        assert relationship['fromColumn'] in columns[relationship['fromTable']]
        assert relationship['toColumn'] in columns[relationship['toTable']]
        assert relationship['crossFilteringBehavior']=='oneDirection'
        assert relationship['fromCardinality']=='many' and relationship['toCardinality']=='one'
    paths = [ROOT/'PilotoVentas.pbip',model_path/'definition.pbism',report/'definition.pbir']
    paths += list((report/'definition').rglob('*.json'))
    visual_paths = list((report/'definition').rglob('visual.json'))
    assert len(visual_paths)==180
    metadata = json.loads((report/'definition/pages/pages.json').read_text(encoding='utf-8'))
    assert set(metadata['pageOrder']) == {'C1_PanoramaClientes','C2_ValorClientes',
        'C3_Recompra','C4_Geografia','C5_Canales','V1_ResumenVentas',
        'P1_PanoramaProduccion','P2_Calidad','P3_Inventario','P4_CentrosTrabajo','P5_Catalogo',
        'V2_Productos','V3_Territorios','V4_Vendedores','V5_Descuentos'}
    for path in paths:
        data = json.loads(path.read_text(encoding='utf-8'))
        if schemas:
            uri = data['$schema']
            schema_check(data,document(uri),uri,str(path.relative_to(ROOT)))
        if path.name=='visual.json':
            position = data['position']
            page = json.loads((path.parents[2]/'page.json').read_text(encoding='utf-8'))
            assert 0<=position['x'] and 0<=position['y']
            assert position['x']+position['width']<=page['width'] and position['y']+position['height']<=page['height']
            for role in data['visual']['query']['queryState'].values():
                for projection in role['projections']:
                    kind, field = next(iter(projection['field'].items()))
                    entity = field['Expression']['SourceRef']['Entity']
                    names = measures[entity] if kind=='Measure' else columns[entity]
                    assert field['Property'] in names
    print('PBIP: 13 tablas, 14 relaciones, 102 medidas y 180 visuales en C1-C5, P1-P5 y V1-V5; referencias/layout OK.')
    print('PBIR: version de contenido 2.0.0, pagina activa y carpetas/identificadores OK.')
    if schemas:
        print(f'Esquemas Microsoft: {len(paths)} archivos de metadatos comprobados.')
    print('Pendiente: apertura, actualizacion, ejecucion DAX y revision visual en Desktop.')


if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--schemas',action='store_true',help='Requiere internet para leer esquemas Microsoft.')
    verify(parser.parse_args().schemas)
