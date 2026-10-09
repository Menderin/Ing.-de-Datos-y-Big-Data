"""Genera parches revisables para P1-P5, sin escribir archivos directamente.

Uso: python generar_produccion.py modelo|P1|P2|P3|P4|P5
Aplicar la salida con apply_patch. Conserva las paginas y medidas existentes.
"""
import difflib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'powerbi/piloto'
REPORT = BASE / 'PilotoVentas.Report/definition/pages'
CHANGES = {}

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def emit(path, value):
    CHANGES[path] = json.dumps(value, ensure_ascii=False, indent=2) + '\n'

def patch():
    print('*** Begin Patch')
    for path, content in CHANGES.items():
        name = path.relative_to(ROOT).as_posix()
        if path.exists():
            previous = path.read_text(encoding='utf-8')
            if previous == content:
                continue
            print('*** Update File: ' + name)
            diff = list(difflib.unified_diff(previous.splitlines(), content.splitlines(), n=3))
            for line in diff[2:]:
                print('@@' if line.startswith('@@') else line)
        else:
            print('*** Add File: ' + name)
            for line in content.splitlines():
                print('+' + line)
    print('*** End Patch')

INTEGER = '#,0'
NUMBER = '#,0.00'
PERCENT = '0.00%'
MEASURES = {}

def measure(table, name, expression, fmt=INTEGER):
    MEASURES.setdefault(table, []).append(dict(name=name, expression=expression,
        formatString=fmt, displayFolder='Produccion/' + name.split()[0]))

for name, expr in {
    'P1 Ordenes': 'COUNTROWS ( FactWorkOrder )',
    'P1 Unidades Ordenadas': 'SUM ( FactWorkOrder[OrderQty] )',
    'P1 Unidades Almacenadas': 'SUM ( FactWorkOrder[StockedQty] )',
    'P1 Unidades Descartadas': 'SUM ( FactWorkOrder[ScrappedQty] )',
    'P2 Ordenes Con Descarte': 'CALCULATE ( COUNTROWS ( FactWorkOrder ), KEEPFILTERS ( FactWorkOrder[ScrappedQty] > 0 ) )',
    'P2 Motivos Utilizados': 'CALCULATE ( DISTINCTCOUNT ( FactWorkOrder[ScrapReasonKey] ), KEEPFILTERS ( FactWorkOrder[ScrappedQty] > 0 ), KEEPFILTERS ( FactWorkOrder[ScrapReasonKey] <> 0 ) )',
    'P2 Unidades Por Motivo': 'IF ( [P1 Unidades Descartadas] > 0, [P1 Unidades Descartadas] )',
}.items():
    measure('FactWorkOrder', name, expr)
measure('FactWorkOrder', 'P2 Costo Estimado', 'SUM ( FactWorkOrder[ScrapCost] )', NUMBER)
measure('FactWorkOrder', 'P2 Tasa Descarte', 'DIVIDE ( [P1 Unidades Descartadas], [P1 Unidades Ordenadas] )', PERCENT)
measure('FactWorkOrder', 'P2 Costo Por Motivo', 'IF ( [P1 Unidades Descartadas] > 0, [P2 Costo Estimado] )', NUMBER)
measure('FactWorkOrder', 'P2 Descarte Acumulado Porcentaje', 'VAR DescarteActual = [P2 Unidades Por Motivo] VAR TablaMotivos = ADDCOLUMNS ( ALLSELECTED ( DimScrapReason ), "@Descarte", [P2 Unidades Por Motivo] ) RETURN IF ( NOT ISBLANK ( DescarteActual ) && HASONEVALUE ( DimScrapReason[ScrapReasonKey] ), DIVIDE ( SUMX ( FILTER ( TablaMotivos, NOT ISBLANK ( [@Descarte] ) && [@Descarte] >= DescarteActual ), [@Descarte] ), SUMX ( TablaMotivos, [@Descarte] ) ) )', PERCENT)
measure('FactWorkOrder', 'P1 Estado', 'IF ( ISBLANK ( [P1 Ordenes] ), "Sin órdenes para la selección. ", "" ) & "Órdenes por fecha de inicio; unidades almacenadas de esas órdenes, no cierres del mes."', '')
measure('FactWorkOrder', 'P2 Estado', '"Descarte / unidades ordenadas. Costo estimado con costo estándar; motivo registrado, no causa demostrada."', '')

measure('FactInventorySnapshot', 'P3 Stock', 'SUM ( FactInventorySnapshot[Quantity] )')
measure('FactInventorySnapshot', 'P3 Valor Estimado', 'SUM ( FactInventorySnapshot[InventoryValue] )', NUMBER)
measure('FactInventorySnapshot', 'P3 Productos Con Registro', 'DISTINCTCOUNT ( FactInventorySnapshot[ProductKey] )')
measure('FactInventorySnapshot', 'P3 Stock Total Producto', 'CALCULATE ( [P3 Stock], REMOVEFILTERS ( DimLocation ), REMOVEFILTERS ( FactInventorySnapshot[LocationKey], FactInventorySnapshot[Shelf], FactInventorySnapshot[Bin] ) )')
measure('FactInventorySnapshot', 'P3 Brecha Reorden', 'VAR StockGlobal = [P3 Stock Total Producto] RETURN IF ( HASONEVALUE ( DimProduct[ProductKey] ) && NOT ISBLANK ( StockGlobal ), StockGlobal - SELECTEDVALUE ( DimProduct[ReorderPoint] ) )')
measure('FactInventorySnapshot', 'P3 Bajo Reorden', 'SUMX ( VALUES ( DimProduct[ProductKey] ), VAR Existencias = [P3 Stock Total Producto] VAR Umbral = CALCULATE ( MAX ( DimProduct[ReorderPoint] ) ) RETURN IF ( NOT ISBLANK ( Existencias ) && Existencias < Umbral, 1, 0 ) )')
measure('FactInventorySnapshot', 'P3 Estado Stock', 'VAR Local = [P3 Stock] VAR TotalProducto = [P3 Stock Total Producto] VAR Umbral = SELECTEDVALUE ( DimProduct[ReorderPoint] ) RETURN IF ( NOT ISBLANK ( Local ) && HASONEVALUE ( DimProduct[ProductKey] ), IF ( TotalProducto < Umbral, "Bajo reorden global", "Sobre umbral global" ) )', '')
measure('FactInventorySnapshot', 'P3 Estado', '"Foto actual, sin histórico. Reorden compara stock global del producto; ubicación filtra stock y valor locales."', '')

measure('FactWorkOrderRouting', 'P4 Operaciones', 'COUNTROWS ( FactWorkOrderRouting )')
measure('FactWorkOrderRouting', 'P4 Horas', 'SUM ( FactWorkOrderRouting[ActualResourceHrs] )', NUMBER)
measure('FactWorkOrderRouting', 'P4 Costo Real', 'SUM ( FactWorkOrderRouting[ActualCost] )', NUMBER)
measure('FactWorkOrderRouting', 'P4 Costo Planificado', 'SUM ( FactWorkOrderRouting[PlannedCost] )', NUMBER)
measure('FactWorkOrderRouting', 'P4 Variacion Costo', 'SUM ( FactWorkOrderRouting[CostVariance] )', NUMBER)
measure('FactWorkOrderRouting', 'P4 Sin Inicio Real', 'CALCULATE ( COUNTROWS ( FactWorkOrderRouting ), KEEPFILTERS ( FactWorkOrderRouting[ActualStartDateKey] = -1 ) )')
measure('FactWorkOrderRouting', 'P4 Estado', '"Operaciones por inicio real, no órdenes. Sin inicio informado: " & FORMAT ( COALESCE ( [P4 Sin Inicio Real], 0 ), "#,0" ) & ". Horas consumidas no equivalen a utilización de capacidad."', '')

measure('DimProduct', 'P5 Productos', 'COUNTROWS ( DimProduct )')
measure('DimProduct', 'P5 Fabricados', 'CALCULATE ( COUNTROWS ( DimProduct ), KEEPFILTERS ( DimProduct[MakeFlag] = TRUE () ) )')
measure('DimProduct', 'P5 No Fabricados', 'CALCULATE ( COUNTROWS ( DimProduct ), KEEPFILTERS ( DimProduct[MakeFlag] = FALSE () ) )')
measure('DimProduct', 'P5 Terminados', 'CALCULATE ( COUNTROWS ( DimProduct ), KEEPFILTERS ( DimProduct[FinishedGoodsFlag] = TRUE () ) )')
measure('DimProduct', 'P5 Estado', '"Catálogo sin filtro temporal. No fabricado internamente no implica compra reciente; sin categoría puede ser una pieza intermedia."', '')

def model():
    path = BASE / 'PilotoVentas.SemanticModel/model.bim'
    doc = read(path)
    tables = {t['name']: t for t in doc['model']['tables']}
    tables['FactSales']['columns'].append(dict(name='ProductKey',dataType='int64',sourceColumn='ProductKey',summarizeBy='none',isHidden=True))
    source = tables['FactSales']['partitions'][0]['source']['expression']
    tables['FactSales']['partitions'][0]['source']['expression'] = [line.replace('{"CustomerKey",', '{"ProductKey", "CustomerKey",') for line in source]
    definitions = {
        'DimProduct': ('ProductKey', 'ProductID ProductName ProductNumber MakeFlag FinishedGoodsFlag Color SafetyStockLevel ReorderPoint StandardCost ListPrice SubcategoryName CategoryName'),
        'DimLocation': ('LocationKey', 'LocationID LocationName CostRate Availability'),
        'DimScrapReason': ('ScrapReasonKey', 'ScrapReasonID ScrapReasonName'),
        'FactWorkOrder': ('FactWorkOrderKey', 'WorkOrderID ProductKey ScrapReasonKey StartDateKey EndDateKey DueDateKey OrderQty StockedQty ScrappedQty ScrapCost'),
        'FactWorkOrderRouting': ('FactRoutingKey', 'WorkOrderID ProductKey LocationKey OperationSequence ScheduledStartDateKey ScheduledEndDateKey ActualStartDateKey ActualEndDateKey ActualResourceHrs PlannedCost ActualCost CostVariance'),
        'FactInventorySnapshot': ('FactInventoryKey', 'ProductKey LocationKey Shelf Bin Quantity InventoryValue'),
    }
    strings = {'ProductName','ProductNumber','Color','SubcategoryName','CategoryName','LocationName','ScrapReasonName','Shelf'}
    decimals = {'StandardCost','ListPrice','CostRate','ScrapCost','PlannedCost','ActualCost','CostVariance','InventoryValue'}
    floats = {'Availability','ActualResourceHrs'}
    for name, (key, fields) in definitions.items():
        if name in tables:
            raise ValueError('Tabla ya existente; no sobrescribir: ' + name)
        names = [key] + fields.split()
        columns = []
        for column in names:
            dtype = 'string' if column in strings else 'boolean' if column.endswith('Flag') else 'decimal' if column in decimals else 'double' if column in floats else 'int64'
            item = dict(name=column, dataType=dtype, sourceColumn=column, summarizeBy='none')
            if column.endswith('Key'):
                item['isHidden'] = True
            if column == key:
                item['isKey'] = True
            if dtype in ('decimal','double'):
                item['formatString'] = NUMBER
            columns.append(item)
        table = dict(name=name, columns=columns, partitions=[dict(name=name, mode='import', source=dict(type='m', expression=[
            'let', '    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),',
            f'    Tabla = Origen{{[Schema = "dbo", Item = "{name}"]}}[Data],',
            '    Seleccion = Table.SelectColumns(Tabla, {' + ', '.join('"'+c+'"' for c in names) + '})',
            'in', '    Seleccion']))])
        if name == 'DimProduct':
            for label, expr in [('Producto','FORMAT ( DimProduct[ProductID], "0" ) & " · " & DimProduct[ProductName]'),
                ('Origen Productivo','IF ( DimProduct[MakeFlag], "Fabricado internamente", "No fabricado internamente" )'),
                ('Tipo Producto','IF ( DimProduct[FinishedGoodsFlag], "Terminado", "Intermedio / no terminado" )')]:
                columns.append(dict(type='calculated',name=label,dataType='string',expression=expr,summarizeBy='none'))
            table['hierarchies'] = [dict(name='Catalogo',levels=[dict(name=c,ordinal=i,column=c) for i,c in enumerate(['CategoryName','SubcategoryName','Producto'])])]
        tables[name] = table
        doc['model']['tables'].append(table)
    for table, measures in MEASURES.items():
        tables[table].setdefault('measures', []).extend(measures)
    # Dimensiones compartidas filtran cada hecho: nunca conectar hechos entre si.
    relationships = [('FactSales','ProductKey','DimProduct','ProductKey')]
    for fact in ('FactWorkOrder','FactWorkOrderRouting','FactInventorySnapshot'):
        relationships.append((fact,'ProductKey','DimProduct','ProductKey'))
    relationships.extend([
        ('FactWorkOrder','ScrapReasonKey','DimScrapReason','ScrapReasonKey'),
        ('FactWorkOrder','StartDateKey','DimDate','DateKey'),
        ('FactWorkOrderRouting','LocationKey','DimLocation','LocationKey'),
        ('FactWorkOrderRouting','ActualStartDateKey','DimDate','DateKey'),
        ('FactInventorySnapshot','LocationKey','DimLocation','LocationKey'),
    ])
    for a,b,c,d in relationships:
        doc['model']['relationships'].append(dict(name=a+'_'+b+'_'+c,fromTable=a,fromColumn=b,toTable=c,toColumn=d,
            fromCardinality='many',toCardinality='one',crossFilteringBehavior='oneDirection',isActive=True))
    for annotation in doc['model'].get('annotations', []):
        if annotation['name'] == 'PBI_QueryOrder':
            annotation['value'] = json.dumps(list(tables))
    emit(path, doc)
    pages = read(REPORT / 'pages.json')
    pages['pageOrder'] = [p for p in pages['pageOrder'] if not p.startswith('P')] 
    at = pages['pageOrder'].index('V1_ResumenVentas')
    pages['pageOrder'][at:at] = [PAGES[p]['folder'] for p in PAGES]
    emit(REPORT/'pages.json', pages)

def col(table, name, label=None):
    return ('Column', table, name, label or name)

def met(table, name, label=None):
    return ('Measure', table, name, label or name)

W='FactWorkOrder'
I='FactInventorySnapshot'
R='FactWorkOrderRouting'
D='DimProduct'
L='DimLocation'
S='DimScrapReason'
DATE_FILTERS=[col('DimDate','Year','Año de inicio'),col('DimDate','MonthName','Mes de inicio')]
PRODUCT_FILTERS=[col(D,'CategoryName','Categoría'),col(D,'SubcategoryName','Subcategoría')]

PAGES = {
 'P1': dict(folder='P1_PanoramaProduccion',title='P1 · Panorama de producción',table=W,
   filters=DATE_FILTERS+PRODUCT_FILTERS,
   kpis=[('P1 Ordenes','Órdenes de fabricación'),('P1 Unidades Ordenadas','Unidades ordenadas'),('P1 Unidades Almacenadas','Unidades almacenadas'),('P1 Unidades Descartadas','Unidades descartadas')],
   charts=[('lineChart','Unidades de las órdenes iniciadas cada mes',col('DimDate','MonthYear','Mes de inicio'),[met(W,'P1 Unidades Ordenadas','Ordenadas'),met(W,'P1 Unidades Almacenadas','Almacenadas')]),
     ('columnChart','Destino de las unidades por categoría',col(D,'CategoryName','Categoría'),[met(W,'P1 Unidades Almacenadas','Almacenadas'),met(W,'P1 Unidades Descartadas','Descartadas')])],
   detail=[col(D,'Producto'),met(W,'P1 Ordenes','Órdenes'),met(W,'P1 Unidades Ordenadas','Ordenadas'),met(W,'P1 Unidades Almacenadas','Almacenadas'),met(W,'P1 Unidades Descartadas','Descartadas'),met(W,'P2 Tasa Descarte','Tasa de descarte')]),
 'P2': dict(folder='P2_Calidad',title='P2 · Calidad y desperdicio',table=W,
   filters=DATE_FILTERS+[col(D,'CategoryName','Categoría'),col(S,'ScrapReasonName','Motivo registrado')],
   kpis=[('P1 Unidades Descartadas','Unidades descartadas'),('P2 Tasa Descarte','Tasa de descarte'),('P2 Costo Estimado','Costo estimado del descarte'),('P2 Ordenes Con Descarte','Órdenes con descarte')],
   charts=[('lineClusteredColumnComboChart','Pareto de unidades descartadas por motivo',col(S,'ScrapReasonName','Motivo'),[met(W,'P2 Unidades Por Motivo','Descartadas')]),
     ('pivotTable','Mapa de calor · unidades descartadas por producto y motivo',col(D,'Producto','Producto'),[met(W,'P2 Unidades Por Motivo','Descartadas')])],
   detail=[col(D,'Producto'),col(S,'ScrapReasonName','Motivo'),met(W,'P2 Unidades Por Motivo','Descartadas'),met(W,'P2 Costo Por Motivo','Costo estimado'),met(W,'P2 Ordenes Con Descarte','Órdenes afectadas')]),
 'P3': dict(folder='P3_Inventario',title='P3 · Inventario y reposición',table=I,
   filters=PRODUCT_FILTERS+[col(L,'LocationName','Ubicación'),col(D,'Producto','Producto')],
   kpis=[('P3 Stock','Unidades en ubicación seleccionada'),('P3 Valor Estimado','Valor estimado del inventario'),('P3 Productos Con Registro','Productos con registro local'),('P3 Bajo Reorden','Productos bajo reorden global')],
   charts=[('clusteredBarChart','Stock por ubicación',col(L,'LocationName','Ubicación'),[met(I,'P3 Stock','Unidades')]),
     ('tableEx','Reposición · stock global frente al umbral',col(D,'Producto','Producto'),[met(I,'P3 Stock Total Producto','Stock global')])],
   detail=[col(D,'Producto'),col(L,'LocationName','Ubicación'),col(I,'Shelf','Estante'),col(I,'Bin','Casillero'),met(I,'P3 Stock','Unidades locales'),met(I,'P3 Valor Estimado','Valor local')]),
 'P4': dict(folder='P4_CentrosTrabajo',title='P4 · Operaciones y centros de trabajo',table=R,
   filters=DATE_FILTERS+[col(L,'LocationName','Centro de trabajo'),col(D,'CategoryName','Categoría')],
   kpis=[('P4 Operaciones','Operaciones registradas'),('P4 Horas','Horas de recurso consumidas'),('P4 Costo Real','Costo real'),('P4 Variacion Costo','Variación real − planificado')],
   charts=[('clusteredBarChart','Horas consumidas por centro',col(L,'LocationName','Centro'),[met(R,'P4 Horas','Horas')]),
     ('pivotTable','Costos y desviación por centro',col(L,'LocationName','Centro'),[met(R,'P4 Costo Planificado','Planificado'),met(R,'P4 Costo Real','Real'),met(R,'P4 Variacion Costo','Variación')])],
   detail=[col(L,'LocationName','Centro'),col(R,'OperationSequence','Secuencia de operación'),met(R,'P4 Operaciones','Operaciones'),met(R,'P4 Horas','Horas'),met(R,'P4 Costo Real','Costo real'),met(R,'P4 Sin Inicio Real','Sin inicio real')]),
 'P5': dict(folder='P5_Catalogo',title='P5 · Composición del catálogo',table=D,
   filters=PRODUCT_FILTERS+[col(D,'Origen Productivo','Origen productivo'),col(D,'Tipo Producto','Tipo de producto')],
   kpis=[('P5 Productos','Productos en catálogo'),('P5 Fabricados','Fabricados internamente'),('P5 No Fabricados','No fabricados internamente'),('P5 Terminados','Productos terminados')],
   charts=[('columnChart','Origen productivo por categoría',col(D,'CategoryName','Categoría'),[met(D,'P5 Fabricados','Fabricados'),met(D,'P5 No Fabricados','No fabricados')]),
     ('treemap','Composición · categoría y subcategoría',col(D,'CategoryName','Categoría'),[met(D,'P5 Productos','Referencias')])],
   detail=[col(D,'Producto'),col(D,'ProductNumber','Código'),col(D,'CategoryName','Categoría'),col(D,'SubcategoryName','Subcategoría'),col(D,'Origen Productivo','Origen'),col(D,'Tipo Producto','Tipo')]),
}

def projection(spec):
    kind, table, name, label = spec
    return dict(field={kind:dict(Expression=dict(SourceRef=dict(Entity=table)),Property=name)},queryRef=table+'.'+name,nativeQueryRef=label)

def lit(value):
    return dict(expr=dict(Literal=dict(Value=value)))

def color(value):
    return dict(solid=dict(color=lit("'"+value+"'")))

def conditional_fill(table, name, cases, default='#FFFFFF'):
    """Colores por expresion nativa PBIR; reglas primero de mayor prioridad."""
    return {'solid': {'color': {'expr': {'Conditional': {
        'Cases': [{'Condition': {'Comparison': {'ComparisonKind': comparison,
            'Left': projection(met(table,name))['field'],
            'Right': {'Literal': {'Value': str(threshold)+'D'}}}},
            'Value': {'Literal': {'Value': "'"+shade+"'"}}}
            for comparison,threshold,shade in cases],
        'DefaultValue': {'Literal': {'Value': "'"+default+"'"}}
    }}}}}

def cell_fill(spec, fill):
    return {'selector': {'data': [{'dataViewWildcard': {'matchingOption': 1}}],
        'metadata': projection(spec)['queryRef']}, 'properties': {'backColor': fill}}

def matrix_objects():
    return {
        'rowHeaders': [{'properties': {'fontSize':lit('10D'),'wordWrap':lit('true')}}],
        'columnHeaders': [{'properties': {'fontSize':lit('10D'),'wordWrap':lit('true'),
            'backColor':color('#EEE8F5'),'fontColor':color('#493164')}}],
        'values': [{'properties': {'fontSize':lit('10D'),'fontColor':color('#24364B')}}],
        'subTotals': [{'properties': {'rowSubtotals':lit('false'),'columnSubtotals':lit('false')}}],
    }

def revise_visual(obj, code, index):
    """Ajustes especificos para Pareto, matrices, reposicion y treemap."""
    query = obj['visual']['query']
    if code=='P1' and index==1:
        obj['visual']['query']['queryState']['Tooltips'] = {'projections':[projection(met(W,'P2 Tasa Descarte','Tasa de descarte'))]}
    if code=='P2':
        obj['position'].update(x=24,width=1232)
        if index==0:
            obj['position'].update(height=300)
            query['queryState']['Y2'] = {'projections':[projection(met(W,'P2 Descarte Acumulado Porcentaje','Acumulado %'))]}
            # Los empates comparten porcentaje acumulado, sin depender de orden oculto.
            obj['visual']['objects']['valueAxis'] = [{'properties': {
                'secShow':lit('true'),'secStart':lit('0D'),'secEnd':lit('1D'),
                'secLabelDisplayUnits':lit('1D'),'secLabelPrecision':lit('0L'),
                'secShowAxisTitle':lit('true'),'secTitleText':lit("'Acumulado %'")}}]
            obj['visual']['objects']['lineStyles'] = [{'properties': {'showMarker':lit('true')}}]
        else:
            obj['position'].update(y=700,height=360)
            query['queryState'] = {
                'Rows': {'projections':[projection(col(D,'Producto','Producto'))]},
                'Columns': {'projections':[projection(col(S,'ScrapReasonName','Motivo'))]},
                'Values': {'projections':[projection(met(W,'P2 Unidades Por Motivo','Descartadas'))]},
            }
            query.pop('sortDefinition',None)
            obj['visual']['objects'] = matrix_objects()
            heat = cell_fill(met(W,'P2 Unidades Por Motivo'),
                conditional_fill(W,'P2 Unidades Por Motivo',[(2,500,'#8060AB'),(2,100,'#B29BCB'),(2,50,'#D1C0E3'),(1,0,'#EEE8F5')]))
            heat['properties']['fontColor'] = conditional_fill(W,'P2 Unidades Por Motivo',[(2,500,'#FFFFFF')],'#24364B')
            obj['visual']['objects']['values'].append(heat)
            obj['visual']['visualContainerObjects']['title'][0]['properties']['text'] = lit("'Mapa de calor · unidades: 1–49 / 50–99 / 100–499 / 500+ (claro → oscuro)'")
    elif code=='P3' and index==1:
        specs = [col(D,'Producto','Producto'),col(D,'ReorderPoint','Umbral'),
            met(I,'P3 Stock Total Producto','Stock global'),met(I,'P3 Brecha Reorden','Brecha'),met(I,'P3 Estado Stock','Estado')]
        query['queryState'] = {'Values':{'projections':[projection(s) for s in specs]}}
        query['sortDefinition'] = {'sort':[{'field':projection(met(I,'P3 Brecha Reorden'))['field'],'direction':'Ascending'}],'isDefaultSort':True}
        obj['visual']['objects'] = {'values': [cell_fill(met(I,'P3 Estado Stock'),
            conditional_fill(I,'P3 Brecha Reorden',[(3,0,'#F8D9C5')],'#EEE8F5')),
            cell_fill(met(I,'P3 Brecha Reorden'),conditional_fill(I,'P3 Brecha Reorden',[(3,0,'#F8D9C5')],'#EEE8F5'))]}
        obj['filterConfig'] = stock_local_filter()
    elif code=='P4' and index==1:
        query['queryState'] = {'Rows':{'projections':[projection(col(L,'LocationName','Centro'))]},
            'Values':{'projections':[projection(met(R,n,label)) for n,label in [
                ('P4 Costo Planificado','Planificado'),('P4 Costo Real','Real'),('P4 Variacion Costo','Variación')]]}}
        query.pop('sortDefinition',None)
        obj['visual']['objects'] = matrix_objects()
        obj['visual']['objects']['values'].append(cell_fill(met(R,'P4 Variacion Costo'),
            conditional_fill(R,'P4 Variacion Costo',[(1,0,'#F8D9C5'),(3,0,'#D8EDE5')],'#EEE8F5')))
    elif code=='P5' and index==1:
        query['queryState'] = {'Group':{'projections':[projection(col(D,'CategoryName','Categoría'))]},
            'Details':{'projections':[projection(col(D,'SubcategoryName','Subcategoría'))]},
            'Values':{'projections':[projection(met(D,'P5 Productos','Referencias'))]}}
        query.pop('sortDefinition',None)
        obj['visual']['objects'] = {'dataPoint':[{'properties':{'fill':color('#8060AB')}}],
            'labels':[{'properties':{'show':lit('true'),'labelDisplayUnits':lit('1D'),'labelPrecision':lit('0L'),'fontSize':lit('10D')}}],
            'categoryLabels':[{'properties':{'show':lit('true'),'fontSize':lit('10D')}}]}

def stock_local_filter():
    return {'filters': [{'name':'SoloStockLocal',
        'field':projection(met(I,'P3 Productos Con Registro'))['field'],
        'type':'Advanced','howCreated':'User','filter':{'Version':2,
            'From':[{'Name':'s','Entity':I,'Type':0}],
            'Where':[{'Condition':{'Comparison':{'ComparisonKind':1,
                'Left':{'Measure':{'Expression':{'SourceRef':{'Source':'s'}},'Property':'P3 Productos Con Registro'}},
                'Right':{'Literal':{'Value':'0L'}}}}}]}}]}

def update_measures():
    path = BASE/'PilotoVentas.SemanticModel/model.bim'
    doc = read(path)
    for table in doc['model']['tables']:
        for item in MEASURES.get(table['name'],[]):
            if item['name'] in ('P2 Descarte Acumulado Porcentaje','P3 Brecha Reorden'):
                existing = next((m for m in table.get('measures',[]) if m['name']==item['name']),None)
                if existing:
                    existing.update(item)
                else:
                    table.setdefault('measures',[]).append(item)
    emit(path,doc)

def page(code):
    config = PAGES[code]
    folder = REPORT / config['folder']
    doc = read(REPORT/'C2_ValorClientes/page.json')
    doc['name'] = config['folder']
    doc['displayName'] = config['title']
    if code=='P2':
        doc['height'] = 1436
    doc['objects']['background'][0]['properties']['color'] = color('#F6F3FA')
    emit(folder/'page.json',doc)
    def visual(template, name, x, y, width, height, title, roles):
        obj = read(REPORT/'C2_ValorClientes/visuals'/template/'visual.json')
        obj['name'] = name
        obj['position'] = dict(x=x,y=y,z=0,width=width,height=height,tabOrder=y+x)
        obj.pop('filterConfig',None)
        query = dict(queryState={role:dict(projections=[projection(s) for s in specs]) for role,specs in roles.items()})
        obj['visual']['query'] = query
        containers = obj['visual']['visualContainerObjects']
        containers['title'][0]['properties']['text'] = lit("'"+title.replace("'","''")+"'")
        containers['title'][0]['properties']['fontColor'] = color('#493164')
        containers['border'][0]['properties']['color'] = color('#E0D7EB')
        if name.startswith('Filtro'):
            containers['background'][0]['properties']['color'] = color('#EEE8F5')
        if name.startswith('Kpi'):
            obj['visual']['objects']['labels'][0]['properties']['color'] = color('#604487')
            measure_name = roles['Values'][0][2]
            fmt = next(m['formatString'] for m in MEASURES[config['table']] if m['name']==measure_name)
            obj['visual']['objects']['labels'][0]['properties']['labelPrecision'] = lit('0L' if fmt==INTEGER else '2L')
        if name == 'Cabecera':
            containers['background'][0]['properties']['color'] = color('#493164')
            containers['title'][0]['properties']['fontColor'] = color('#FFFFFF')
        return obj
    head = visual('Cabecera','Cabecera',24,16,1232,80,config['title'],{'Values':[met(config['table'],code+' Estado')]})
    emit(folder/'visuals/Cabecera/visual.json',head)
    for i,spec in enumerate(config['filters']):
        emit(folder/f'visuals/Filtro{i}/visual.json', visual('Filtro0',f'Filtro{i}',24+i*312,112,296,88,spec[3],{'Values':[spec]}))
    for i,(name,label) in enumerate(config['kpis']):
        emit(folder/f'visuals/Kpi{i}/visual.json', visual('Kpi0',f'Kpi{i}',24+i*312,224,296,128,label,{'Values':[met(config['table'],name,label)]}))
    for i,(kind,title,category,values) in enumerate(config['charts']):
        obj = visual('Ranking',f'Grafico{i}',24+i*632,376,600,272,title,{'Category':[category],'Y':values})
        obj['visual']['visualType'] = kind
        sort = category if kind=='lineChart' else values[0]
        obj['visual']['query']['sortDefinition'] = dict(sort=[dict(field=projection(sort)['field'],direction='Ascending' if kind=='lineChart' else 'Descending')],isDefaultSort=True)
        obj['visual']['objects'] = {'dataPoint':[{'properties':{'defaultColor':color('#8060AB')}}, *[{'selector':{'metadata':projection(s)['queryRef']},'properties':{'fill':color(c)}} for s,c in zip(values,['#8060AB','#B29BCB'])]]}
        revise_visual(obj,code,i)
        emit(folder/f'visuals/Grafico{i}/visual.json',obj)
    detail = visual('Detalle','Detalle',24,672,1232,328,'Detalle · '+config['title'].split(' · ')[1],{'Values':config['detail']})
    if code=='P2':
        detail['position'].update(y=1084)
    if code == 'P3':
        detail['filterConfig'] = {'filters': [{
            'name': 'SoloStockLocal', 'field': projection(met(I,'P3 Productos Con Registro'))['field'],
            'type': 'Advanced', 'howCreated': 'User', 'filter': {
                'Version': 2, 'From': [{'Name': 's', 'Entity': I, 'Type': 0}],
                'Where': [{'Condition': {'Comparison': {
                    'ComparisonKind': 1,
                    'Left': {'Measure': {'Expression': {'SourceRef': {'Source': 's'}}, 'Property': 'P3 Productos Con Registro'}},
                    'Right': {'Literal': {'Value': '0L'}}
                }}}]
            }
        }]}
    emit(folder/'visuals/Detalle/visual.json',detail)

if __name__ == '__main__':
    if sys.argv[1]=='modelo':
        model()
    elif sys.argv[1]=='medidas':
        update_measures()
    elif sys.argv[1].endswith('Visuales'):
        page(sys.argv[1][:2])
        CHANGES = {p:v for p,v in CHANGES.items() if p.name=='page.json' or p.parent.name in ('Grafico0','Grafico1','Detalle')}
    elif sys.argv[1]=='P3Detalle':
        page('P3')
        CHANGES = {p: v for p, v in CHANGES.items() if p.name=='visual.json' and p.parent.name=='Detalle'}
    else:
        page(sys.argv[1])
    patch()
