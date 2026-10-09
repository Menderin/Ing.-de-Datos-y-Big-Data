"""Controles SQL de reportabilidad. Solo lectura del DW; no ejecuta el ETL."""
import argparse
import json
import sys
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'database' / 'etl'))
from run_etl import execute_sql, load_env_password, validate_name


def packets(output, prefix):
    result = {}
    for line in output.splitlines():
        if line.startswith(prefix + '|'):
            _, code, payload = line.split('|', 2)
            if code in result:
                raise ValueError('Control duplicado: ' + code)
            result[code] = json.loads(payload, parse_float=Decimal)
    return result


def check_controls(r, p):
    expected = {f'{group}{i}' for group in 'CPV' for i in range(1, 6)}
    if set(r) != expected:
        raise ValueError('Faltan reportes o hay codigos inesperados.')
    expected_pilot = {'sin_filtros', 'anio_2013', 'southwest', '2013_southwest',
                      'junio_2013', 'online', '2013_southwest_online', 'sin_ventas_2010'}
    if set(p) != expected_pilot:
        raise ValueError('Faltan casos de filtros del piloto.')
    checks = []

    def equal(label, a, b, tolerance=Decimal('0.00001')):
        # SUM sin filas = NULL; no convertirlo en un dato inventado en el reporte.
        av = Decimal(0) if a is None else Decimal(a)
        bv = Decimal(0) if b is None else Decimal(b)
        if abs(av-bv) > tolerance:
            raise ValueError(f'{label}: {a} != {b}')
        checks.append(label)

    equal('C1 tipos = cartera', (r['C1']['individuales'] or 0)+(r['C1']['tiendas'] or 0), r['C1']['registrados'])
    equal('C3 segmentos = compradores', sum(r['C3'][k] for k in ('frecuentes','recurrentes','compra_unica')), r['C1']['compradores'])
    equal('C5 canales = ordenes', r['C5']['ordenes_online']+r['C5']['ordenes_asistidas'], r['V1']['ordenes'])
    equal('C5 ventas por canal', (r['C5']['ventas_online'] or 0)+(r['C5']['ventas_asistidas'] or 0), r['V1']['ventas'])
    equal('P1 conformes + descarte', (r['P1']['almacenadas'] or 0)+(r['P1']['desechadas'] or 0), r['P1']['planificadas'])
    equal('P4 diferencia de costos', (r['P4']['costo_real'] or 0)-(r['P4']['costo_planificado'] or 0), r['P4']['variacion'])
    equal('V1 venta = costo + margen', r['V1']['ventas'], (r['V1']['costo'] or 0)+(r['V1']['margen'] or 0))
    equal('V2 unidades', r['V2']['unidades'], r['V1']['unidades'])
    equal('V3 grupos = ventas', sum(r['V3'][k] or 0 for k in ('ventas_norteamerica','ventas_internacionales','ventas_otro_grupo')), r['V1']['ventas'])
    equal('V4 ventas asistidas', r['V4']['ventas_asistidas'], r['C5']['ventas_asistidas'])
    equal('V5 ofertas + regular', (r['V5']['ventas_oferta'] or 0)+(r['V5']['ventas_regular'] or 0), r['V1']['ventas'])
    # DiscountAmount usa MONEY (4 decimales), LineTotal conserva 6.
    tolerance = Decimal('0.00005') * (r['V5']['lineas_descuento'] or 0) + Decimal('0.01')
    equal('V5 bruto - descuento = neto (redondeo)', (r['V5']['venta_bruta'] or 0)-(r['V5']['descuento'] or 0), r['V5']['venta_neta'], tolerance)
    for key in ('ventas','costo','margen','ordenes','ticket','unidades'):
        equal('Piloto sin filtros: '+key, p['sin_filtros'][key], r['V1'][key])
    for code, values in p.items():
        equal('Piloto costo + margen: '+code, values['ventas'], (values['costo'] or 0)+(values['margen'] or 0))
        if values['ordenes'] == 0 and values['ticket'] is not None:
            raise ValueError('DIVIDE sin ordenes debe ser NULL/BLANK: '+code)
    return checks


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--database', default='AdventureWorksDW')
    parser.add_argument('--json', action='store_true', help='Emitir controles en JSON para guardar una referencia.')
    args = parser.parse_args()
    try:
        validate_name(args.database)
        password = load_env_password(ROOT)
        results = []
        for filename in ('01_controles_reportes.sql','03_piloto_ventas.sql'):
            sql = Path(__file__).with_name(filename).read_text(encoding='utf-8')
            sql = sql.replace('USE AdventureWorksDW;', f'USE [{args.database}];')
            results.append(execute_sql(sql, password))
        r, p = packets(results[0], 'REPORT'), packets(results[1], 'PILOT')
        checks = check_controls(r, p)
        for marker in ('CHECK|join_fecha_territorio|OK','CHECK|reconciliacion_graficos|OK'):
            if marker not in results[1]:
                raise ValueError('Falta control SQL: '+marker)
        if args.json:
            print(json.dumps({'database': args.database, 'reports': r, 'pilot': p, 'checks': checks},
                             ensure_ascii=False, indent=2, default=str))
        else:
            print('VALIDACION SQL DE REPORTES\n' + '-' * 72)
            print('15 reportes consultados; 8 escenarios del piloto de ventas.')
            for code in sorted(r):
                print(code+'  OK - indicadores obtenidos del DW')
            print(f'\n{len(checks)+2} controles de consistencia: OK')
            print('Esto valida SQL. DAX, filtros y visuales requieren Power BI Desktop.')
        return 0
    except Exception as exc:
        print('ERROR: '+str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
