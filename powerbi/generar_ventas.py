"""Parches PBIP de V1-V5. No modifica el DW ni escribe archivos directamente."""
import json
import sys
import generar_produccion as g

F = 'FactSales'
D = 'DimProduct'
T = 'DimTerritory'
S = 'DimSalesPerson'
O = 'DimSpecialOffer'
C = g.col
M = lambda name, label=None: g.met(F, name, label)
NEW = []

def measure(name, expr, fmt=g.NUMBER):
    NEW.append(dict(name=name, expression=expr, formatString=fmt,
                    displayFolder='Ventas/' + name.split()[0]))

measure('V2 Productos Vendidos', 'DISTINCTCOUNT ( FactSales[ProductKey] )', g.INTEGER)
measure('V2 Precio Neto Unidad', 'DIVIDE ( [Ventas Netas], [Unidades Vendidas] )')
measure('V2 Posicion Producto', 'VAR VentaActual = [Ventas Netas] VAR ProductoActual = SELECTEDVALUE ( DimProduct[ProductKey] ) VAR Universo = ADDCOLUMNS ( ALLSELECTED ( DimProduct ), "@Venta", [Ventas Netas] ) RETURN IF ( NOT ISBLANK ( VentaActual ) && NOT ISBLANK ( ProductoActual ), 1 + COUNTROWS ( FILTER ( Universo, NOT ISBLANK ( [@Venta] ) && ( [@Venta] > VentaActual || ( [@Venta] = VentaActual && DimProduct[ProductKey] < ProductoActual ) ) ) ) )', g.INTEGER)
measure('V2 Venta Top 10', 'IF ( NOT ISBLANK ( [V2 Posicion Producto] ) && [V2 Posicion Producto] <= 10, [Ventas Netas] )')
measure('V3 Territorios Con Venta', 'DISTINCTCOUNT ( FactSales[TerritoryKey] )', g.INTEGER)
measure('V3 Compradores', 'DISTINCTCOUNT ( FactSales[CustomerKey] )', g.INTEGER)
measure('V3 Participacion Grupo', 'DIVIDE ( [Ventas Netas], CALCULATE ( [Ventas Netas], ALLSELECTED ( DimTerritory[Group] ) ) )', g.PERCENT)
for name, expr, fmt in [
    ('V4 Ventas', 'CALCULATE ( [Ventas Netas], KEEPFILTERS ( DimSalesPerson[SalesPersonKey] <> 0 ) )', g.NUMBER),
    ('V4 Ordenes', 'CALCULATE ( DISTINCTCOUNT ( FactSales[SalesOrderID] ), KEEPFILTERS ( DimSalesPerson[SalesPersonKey] <> 0 ) )', g.INTEGER),
    ('V4 Vendedores Activos', 'CALCULATE ( DISTINCTCOUNT ( FactSales[SalesPersonKey] ), KEEPFILTERS ( DimSalesPerson[SalesPersonKey] <> 0 ) )', g.INTEGER),
    ('V4 Margen', 'CALCULATE ( [Margen Bruto], KEEPFILTERS ( DimSalesPerson[SalesPersonKey] <> 0 ) )', g.NUMBER),
    ('V4 Ticket', 'DIVIDE ( [V4 Ventas], [V4 Ordenes] )', g.NUMBER),
    ('V4 Margen Porcentaje', 'DIVIDE ( [V4 Margen], [V4 Ventas] )', g.PERCENT),
    ('V4 Compradores', 'CALCULATE ( DISTINCTCOUNT ( FactSales[CustomerKey] ), KEEPFILTERS ( DimSalesPerson[SalesPersonKey] <> 0 ) )', g.INTEGER),
]:
    measure(name, expr, fmt)
measure('V5 Venta Bruta', 'SUMX ( FactSales, FactSales[OrderQty] * FactSales[UnitPrice] )')
measure('V5 Descuento', 'SUM ( FactSales[DiscountAmount] )')
measure('V5 Tasa Descuento', 'DIVIDE ( [V5 Descuento], [V5 Venta Bruta] )', g.PERCENT)
measure('V5 Venta Con Descuento', 'CALCULATE ( [Ventas Netas], KEEPFILTERS ( FactSales[UnitPriceDiscount] > 0 ) )')
measure('V5 Ajuste Redondeo', '[Ventas Netas] - ( [V5 Venta Bruta] - [V5 Descuento] )', '#,0.000000')
measure('V5 Puente', 'IF ( [Ordenes] > 0, SWITCH ( SELECTEDVALUE ( PuenteVenta[Paso] ), 1, [V5 Venta Bruta], 2, - [V5 Descuento], 3, IF ( ABS ( [V5 Ajuste Redondeo] ) > 0.00000001, [V5 Ajuste Redondeo] ) ) )')
notes = {
    'V1': 'Venta neta sin impuestos ni flete. Margen estimado con costo estándar vigente, no utilidad neta.',
    'V2': 'Top 10 por venta neta en la selección; empates resueltos por ID. Margen con costo estándar vigente.',
    'V3': 'Territorio de la venta, no domicilio del cliente. Un comprador puede comprar en varios territorios.',
    'V4': 'Solo ventas con vendedor identificado. Sin cuotas ni metas; no mide cumplimiento ni causalidad.',
    'V5': 'Oferta registrada no implica descuento aplicado. La cascada concilia redondeos; total final = venta neta.',
}
for code, note in notes.items():
    activity = '[V4 Ordenes]' if code == 'V4' else '[Ordenes]'
    measure(code+' Estado', f'IF ( COALESCE ( {activity}, 0 ) = 0, "Sin ventas para la selección. ", "" ) & "{note}"', '')

dates = [C('DimDate','Year','Año'), C('DimDate','MonthName','Mes')]
territory = C(T,'TerritoryName','Territorio de venta')
channel = C(F,'Canal','Canal de venta')
g.PAGES = {
 'V1': dict(folder='V1_ResumenVentas', title='V1 · Panorama de ventas', table=F,
    filters=dates+[territory,channel],
    kpis=[('Ventas Netas','Venta neta'),('Margen Bruto','Margen estimado'),('Ordenes','Órdenes'),('Ticket Promedio','Ticket promedio')],
    charts=[('lineChart','Venta, costo y margen por mes',C('DimDate','MonthYear'),[M('Ventas Netas'),M('Costo de Ventas'),M('Margen Bruto')]),
            ('donutChart','Composición de venta por canal',channel,[M('Ventas Netas')])],
    detail=[C('DimDate','MonthYear','Mes'),M('Ventas Netas'),M('Costo de Ventas'),M('Margen Bruto'),M('Margen Bruto %'),M('Ordenes'),M('Ticket Promedio'),M('Unidades Vendidas')]),
 'V2': dict(folder='V2_Productos', title='V2 · Productos y mezcla comercial', table=F,
    filters=dates+[C(D,'CategoryName','Categoría'),C(D,'SubcategoryName','Subcategoría')],
    kpis=[('Ventas Netas','Venta neta'),('Unidades Vendidas','Unidades vendidas'),('V2 Productos Vendidos','Productos con venta'),('V2 Precio Neto Unidad','Precio neto por unidad')],
    charts=[('clusteredBarChart','Top 10 productos por venta neta',C(D,'Producto'),[M('V2 Venta Top 10')]),
            ('clusteredColumnChart','Mezcla comercial · categoría → subcategoría → producto',C(D,'CategoryName'),[M('Ventas Netas')])],
    detail=[C(D,'Producto'),C(D,'CategoryName','Categoría'),M('Ventas Netas'),M('Unidades Vendidas'),M('V2 Precio Neto Unidad'),M('Margen Bruto','Margen estimado'),M('Margen Bruto %')]),
 'V3': dict(folder='V3_Territorios', title='V3 · Mercados y territorios de venta', table=F,
    filters=dates+[C(T,'Group','Grupo comercial'),channel],
    kpis=[('Ventas Netas','Venta neta'),('V3 Territorios Con Venta','Territorios con venta'),('V3 Compradores','Compradores distintos'),('Ticket Promedio','Ticket promedio')],
    charts=[('columnChart','Evolución mensual por grupo comercial',C('DimDate','MonthYear'),[M('Ventas Netas')]),
            ('clusteredBarChart','Mercados · grupo → país → territorio',C(T,'Group'),[M('Ventas Netas')])],
    detail=[C(T,'Group','Grupo'),C(T,'CountryRegionCode','País'),territory,M('Ventas Netas'),M('Ordenes'),M('V3 Compradores'),M('Ticket Promedio'),M('Margen Bruto %')]),
 'V4': dict(folder='V4_Vendedores', title='V4 · Desempeño de vendedores', table=F,
    filters=dates+[territory,C(S,'Vendedor','Vendedor')],
    kpis=[('V4 Ventas','Venta con vendedor'),('V4 Vendedores Activos','Vendedores con ventas'),('V4 Ordenes','Órdenes con vendedor'),('V4 Ticket','Ticket promedio')],
    charts=[('clusteredBarChart','Venta neta por vendedor',C(S,'Vendedor'),[M('V4 Ventas')]),
            ('lineChart','Venta con vendedor por mes',C('DimDate','MonthYear'),[M('V4 Ventas')])],
    detail=[C(S,'Vendedor'),M('V4 Ventas'),M('V4 Ordenes'),M('V4 Compradores'),M('V4 Ticket'),M('V4 Margen','Margen estimado'),M('V4 Margen Porcentaje')]),
 'V5': dict(folder='V5_Descuentos', title='V5 · Descuentos y ofertas', table=F,
    filters=dates+[C(O,'Type','Tipo de oferta registrada'),channel],
    kpis=[('V5 Venta Bruta','Venta antes del descuento'),('V5 Descuento','Descuento aplicado'),('Ventas Netas','Venta neta'),('V5 Tasa Descuento','Descuento / venta bruta')],
    charts=[('waterfallChart','Venta bruta → descuentos → ajuste → venta neta (Total)',C('PuenteVenta','Concepto'),[M('V5 Puente')]),
            ('donutChart','Venta neta con y sin descuento aplicado',C(F,'Descuento Aplicado'),[M('Ventas Netas')])],
    detail=[C(O,'Description','Oferta registrada'),C(O,'Type','Tipo'),M('V5 Venta Bruta'),M('V5 Descuento'),M('Ventas Netas'),M('V5 Tasa Descuento'),M('V5 Venta Con Descuento'),M('Margen Bruto %')]),
}

def model():
    path = g.BASE/'PilotoVentas.SemanticModel/model.bim'
    doc = g.read(path)
    tables = {t['name']:t for t in doc['model']['tables']}
    extra = {'SalesPersonKey':'int64','SpecialOfferKey':'int64','UnitPrice':'decimal',
             'UnitPriceDiscount':'decimal','DiscountAmount':'decimal'}
    existing = {c['name'] for c in tables[F]['columns']}
    for name, dtype in extra.items():
        if name not in existing:
            tables[F]['columns'].append(dict(name=name,dataType=dtype,sourceColumn=name,summarizeBy='none',isHidden=True))
    source = tables[F]['partitions'][0]['source']['expression']
    imported = [c['sourceColumn'] for c in tables[F]['columns'] if 'sourceColumn' in c]
    tables[F]['partitions'][0]['source']['expression'] = [
        '    Seleccion = Table.SelectColumns(Tabla, {'+', '.join(json.dumps(c) for c in imported)+'})'
        if 'Table.SelectColumns' in line else line for line in source]
    if 'Descuento Aplicado' not in existing:
        tables[F]['columns'].append(dict(type='calculated',name='Descuento Aplicado',dataType='string',summarizeBy='none',
            expression='IF ( FactSales[UnitPriceDiscount] > 0, "Con descuento", "Sin descuento" )'))
    for name, fields in {S:['SalesPersonKey','BusinessEntityID','FullName','JobTitle'],O:['SpecialOfferKey','SpecialOfferID','Description','DiscountPct','Type','Category']}.items():
        if name not in tables:
            columns = [dict(name=c,dataType='int64' if c.endswith(('Key','ID')) else 'decimal' if c=='DiscountPct' else 'string',sourceColumn=c,summarizeBy='none',isHidden=c.endswith('Key')) for c in fields]
            columns[0]['isKey'] = True
            table = dict(name=name,columns=columns,partitions=[dict(name=name,mode='import',source=dict(type='m',expression=[
                'let','    Origen = Sql.Database("localhost,1433", "AdventureWorksDW"),',
                f'    Tabla = Origen{{[Schema="dbo", Item="{name}"]}}[Data],',
                '    Seleccion = Table.SelectColumns(Tabla, {'+', '.join(json.dumps(c) for c in fields)+'})','in','    Seleccion']))])
            if name==S:
                columns.append(dict(type='calculated',name='Vendedor',dataType='string',summarizeBy='none',expression='FORMAT ( DimSalesPerson[BusinessEntityID], "0" ) & " · " & DimSalesPerson[FullName]'))
            doc['model']['tables'].append(table)
            tables[name] = table
        key = fields[0]
        relname = F+'_'+key+'_'+name
        if not any(r['name']==relname for r in doc['model']['relationships']):
            doc['model']['relationships'].append(dict(name=relname,fromTable=F,fromColumn=key,toTable=name,toColumn=key,fromCardinality='many',toCardinality='one',crossFilteringBehavior='oneDirection',isActive=True))
    if 'PuenteVenta' not in tables:
        doc['model']['tables'].append(dict(name='PuenteVenta',columns=[
            dict(name='Paso',dataType='int64',sourceColumn='Paso',summarizeBy='none',isHidden=True),
            dict(name='Concepto',dataType='string',sourceColumn='Concepto',summarizeBy='none',sortByColumn='Paso')],
            partitions=[dict(name='PuenteVenta',mode='import',source=dict(type='m',expression=[
                '#table(type table [Paso=Int64.Type, Concepto=text], {{1,"Venta bruta"},{2,"Descuentos"},{3,"Ajuste de redondeo"}})']))]))
    measures = tables[F].setdefault('measures',[])
    for item in NEW:
        old = next((m for m in measures if m['name']==item['name']),None)
        if old: old.update(item)
        else: measures.append(item)
    for annotation in doc['model'].get('annotations',[]):
        if annotation['name']=='PBI_QueryOrder':
            annotation['value']=json.dumps([t['name'] for t in doc['model']['tables']])
    g.emit(path,doc)
    pages = g.read(g.REPORT/'pages.json')
    pages['pageOrder']=[p for p in pages['pageOrder'] if not p.startswith('V')]+[p['folder'] for p in g.PAGES.values()]
    g.emit(g.REPORT/'pages.json',pages)

def sales_filter(measure_name='Ordenes', name='ConVentas'):
    return {'filters':[{'name':name,'field':g.projection(M(measure_name))['field'],'type':'Advanced','howCreated':'User',
        'filter':{'Version':2,'From':[{'Name':'s','Entity':F,'Type':0}],
        'Where':[{'Condition':{'Comparison':{'ComparisonKind':1,
            'Left':{'Measure':{'Expression':{'SourceRef':{'Source':'s'}},'Property':measure_name}},'Right':{'Literal':{'Value':'0L'}}}}}]}}]}

def series_colors(spec, values):
    return [dict(selector={'data':[{'scopeId':{'Comparison':{'ComparisonKind':0,
        'Left':g.projection(spec)['field'],'Right':{'Literal':{'Value':"'"+label+"'"}}}}}]},
        properties={'fill':g.color(shade)}) for label,shade in values]

def page(code):
    # Reutilizar exclusivamente el layout aprobado, no los ajustes de producción.
    g.revise_visual=lambda *args:None
    current=g.read(g.BASE/'PilotoVentas.SemanticModel/model.bim')
    g.MEASURES={F:next(t for t in current['model']['tables'] if t['name']==F)['measures']+NEW}
    g.page(code)
    folder=g.REPORT/g.PAGES[code]['folder']
    for path, content in list(g.CHANGES.items()):
        if path.is_relative_to(folder):
            for old,new in {'#F6F3FA':'#F2F7F4','#493164':'#214E3B','#E0D7EB':'#D5E5DC','#EEE8F5':'#E8F1EC','#604487':'#286849','#8060AB':'#32936F','#B29BCB':'#91C7A8'}.items():
                content=content.replace(old,new)
            obj=json.loads(content)
            if path.name=='visual.json':
                visual=obj['visual']; name=obj['name']; query=visual['query']['queryState']
                if name.startswith('Filtro'):
                    obj['filterConfig']=sales_filter('V4 Ordenes' if code=='V4' else 'Ordenes')
                if name=='Detalle':
                    obj['filterConfig']=sales_filter('V4 Ordenes' if code=='V4' else 'Ordenes')
                if name in ('Grafico0','Grafico1'):
                    kind=visual['visualType']
                    if kind=='donutChart':
                        # El anillo nativo usa Category/Y, no Legend/Values.
                        visual['objects']['dataPoint'] += series_colors(channel if code=='V1' else C(F,'Descuento Aplicado'),
                            [('Online','#32936F'),('Asistido','#214E3B')] if code=='V1' else [('Con descuento','#A66B38'),('Sin descuento','#32936F')])
                    if code=='V1' and name=='Grafico0':
                        for spec,shade in zip(g.PAGES[code]['charts'][0][3],['#32936F','#91C7A8','#A66B38']):
                            for item in visual['objects']['dataPoint']:
                                if item.get('selector',{}).get('metadata')==g.projection(spec)['queryRef']:
                                    item['properties']['fill']=g.color(shade)
                    if (code,name) in [('V2','Grafico1'),('V3','Grafico1')]:
                        specs=[C(D,n) for n in ['CategoryName','SubcategoryName','Producto']] if code=='V2' else [C(T,n) for n in ['Group','CountryRegionCode','TerritoryName']]
                        query['Category']['projections']=[dict(g.projection(spec),active=i==0) for i,spec in enumerate(specs)]
                    if code=='V3' and name=='Grafico0':
                        query['Series']={'projections':[g.projection(C(T,'Group'))]}
                        visual['objects']['dataPoint'] += series_colors(C(T,'Group'),[('North America','#214E3B'),('Europe','#32936F'),('Pacific','#91C7A8')])
                        visual['query']['sortDefinition']={'sort':[{'field':g.projection(C('DimDate','MonthYear'))['field'],'direction':'Ascending'}],'isDefaultSort':True}
                    if code=='V5' and name=='Grafico0':
                        visual['query']['sortDefinition']={'sort':[{'field':g.projection(C('PuenteVenta','Concepto'))['field'],'direction':'Ascending'}],'isDefaultSort':True}
                        visual['objects']={'sentimentColors':[{'properties':{'increaseFill':g.color('#32936F'),
                            'decreaseFill':g.color('#A66B38'),'totalFill':g.color('#214E3B'),'otherFill':g.color('#91C7A8')}}]}
            if code=='V1' and obj.get('name','').startswith('Filtro'):
                newname=['FiltroAnio','FiltroMes','FiltroTerritorio','FiltroCanal'][int(obj['name'][-1])]
                obj['name']=newname
                del g.CHANGES[path]
                path=path.parent.parent/newname/'visual.json'
            g.emit(path,obj)
    return folder

if __name__=='__main__':
    if sys.argv[1]=='modelo':
        model()
        g.patch()
    else:
        folder=page(sys.argv[1])
        # Quitar solo los visuales reemplazados en la página V1; otras páginas intactas.
        obsolete=[p for p in folder.glob('visuals/*/visual.json') if p not in g.CHANGES]
        print('*** Begin Patch')
        for path in obsolete:
            print('*** Delete File: '+path.relative_to(g.ROOT).as_posix())
        # La salida habitual incluye sus propias delimitaciones.
        import contextlib
        import io
        stream=io.StringIO()
        with contextlib.redirect_stdout(stream):g.patch()
        print('\n'.join(stream.getvalue().splitlines()[1:-1]))
        print('*** End Patch')
