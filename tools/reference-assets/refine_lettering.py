#!/usr/bin/env python3
"""Optical derivatives, not a measured reconstruction.

Requires svgpathtools==1.7.2, shapely==2.0.7, numpy. Produces NEW imagesets only.
The historic assets remain the unmodified extraction of CC0 authored outlines.
"""
from pathlib import Path
import copy, hashlib, json, math
import numpy as np
import xml.etree.ElementTree as ET
from svgpathtools import parse_path
from svgpathtools.parser import parse_transform
from svgpathtools.path import transform
from shapely.geometry import Polygon, GeometryCollection
from shapely.ops import unary_union

HERE=Path(__file__).resolve().parent
ASSETS=HERE.parent.parent/'astologia hologia'/'Assets.xcassets'
SVG='http://www.w3.org/2000/svg'
ET.register_namespace('',SVG)
TANGENT_SCALE=0.84
GLYPH_FILL="#dfcb91"  # Optical gold adjustment, not a sampled physical paint color.
GLYPH_INSET=1.4  # 128-unit glyph viewBox, 112-unit historic maximum ink dimension
CURVE_TOLERANCE=0.02  # below 0.02px at a 128px rendering
center=np.array([980.32275,-192.64893])


def source_paths(node, matrix=None):
    matrix=np.identity(3) if matrix is None else matrix
    matrix=matrix @ parse_transform(node.get('transform',''))
    if node.tag.endswith('path'):
        yield node,transform(parse_path(node.get('d')),matrix)
    for child in node:
        yield from source_paths(child,matrix)


def write_asset(name,root):
    assert name.startswith('refined_')
    folder=ASSETS/f'{name}.imageset';folder.mkdir(exist_ok=True)
    ET.indent(root)
    ET.ElementTree(root).write(folder/f'{name}.svg',encoding='utf-8',xml_declaration=True)
    (folder/'Contents.json').write_text(json.dumps({
        'images':[{'filename':f'{name}.svg','idiom':'universal'}],
        'info':{'author':'xcode','version':1},
        'properties':{'preserves-vector-representation':True}
    },indent=2)+'\n')


def svg(size):
    return ET.Element(f'{{{SVG}}}svg',width=str(size),height=str(size),viewBox=f'0 0 {size} {size}')


ring=ET.parse(ASSETS/'historic_czech_numerals.imageset'/'historic_czech_numerals.svg').getroot()
normalized=ring[0]
ring_metadata=[]
for child in list(normalized):
    boxes=[p.bbox() for _,p in source_paths(child)]
    bounds=(min(b[0] for b in boxes),max(b[1] for b in boxes),min(b[2] for b in boxes),max(b[3] for b in boxes))
    cx,cy=(bounds[0]+bounds[1])/2,(bounds[2]+bounds[3])/2
    tangent=math.degrees(math.atan2(cy-center[1],cx-center[0]))+90
    wrapper=ET.Element(f'{{{SVG}}}g',transform=f'translate({cx:.12f} {cy:.12f}) rotate({tangent:.12f}) scale({TANGENT_SCALE} 1) rotate({-tangent:.12f}) translate({-cx:.12f} {-cy:.12f})')
    normalized.remove(child);wrapper.append(child);normalized.append(wrapper)
    ring_metadata.append({'source_id':child.get('id'),'center':[cx,cy],'tangent_degrees':tangent})
write_asset('refined_czech_numerals',ring)


def line_distance(point,a,b):
    if abs(b-a)<1e-14:return abs(point-a)
    return abs((point-a).imag*(b-a).real-(point-a).real*(b-a).imag)/abs(b-a)


def flatten_segment(segment,lo=0.,hi=1.,depth=0):
    a,b=segment.point(lo),segment.point(hi)
    error=max(line_distance(segment.point(lo+(hi-lo)*f),a,b) for f in (.25,.5,.75))
    if error<CURVE_TOLERANCE or depth>=16:return [a,b]
    mid=(lo+hi)/2
    return flatten_segment(segment,lo,mid,depth+1)[:-1]+flatten_segment(segment,mid,hi,depth+1)


def filled_geometry(path):
    result=GeometryCollection()
    for subpath in path.continuous_subpaths():
        points=[]
        for segment in subpath:
            points.extend(flatten_segment(segment)[:-1])
        points.append(subpath[-1].end)
        if len(points)<3:continue
        polygon=Polygon([(p.real,p.imag) for p in points])
        if not polygon.is_valid:polygon=polygon.buffer(0)
        # The historic source glyphs explicitly use evenodd fill.
        result=result.symmetric_difference(polygon)
    return result


def polygons(geometry):
    if geometry.is_empty:return []
    if geometry.geom_type=='Polygon':return [geometry]
    return [p for g in geometry.geoms for p in polygons(g)]


def structure(geometry):
    ps=polygons(geometry)
    return {'components':len(ps),'holes':sum(len(p.interiors) for p in ps),'area':geometry.area}


def polygon_d(geometry):
    chunks=[]
    for polygon in polygons(geometry):
        for contour in [polygon.exterior]+list(polygon.interiors):
            coords=list(contour.coords)
            chunks.append('M '+' L '.join(f'{x:.5f},{y:.5f}' for x,y in coords[:-1])+' Z')
    return ' '.join(chunks)


zodiac_metadata={}
for historic in sorted(ASSETS.glob('historic_zodiac_*.imageset')):
    name=historic.name.removeprefix('historic_zodiac_').removesuffix('.imageset')
    historic_svg=ET.parse(historic/f'historic_zodiac_{name}.svg').getroot()
    geometries=[filled_geometry(path) for _,path in source_paths(historic_svg)]
    before=unary_union(geometries)
    baseline=structure(before)
    inset=GLYPH_INSET
    while inset>=0.2:
        after=before.buffer(-inset,join_style=2,mitre_limit=2)
        final=structure(after)
        if final['components']==baseline['components'] and final['holes']==baseline['holes'] and not after.is_empty:break
        inset=round(inset-0.1,6)
    else:raise ValueError(f'{name}: cannot inset while preserving components and counters')
    out=svg(128)
    ET.SubElement(out,f'{{{SVG}}}path',d=polygon_d(after),fill=GLYPH_FILL,**{'fill-rule':'evenodd'})
    write_asset(f'refined_zodiac_{name}',out)
    zodiac_metadata[name]={'requested_inset':GLYPH_INSET,'applied_inset':inset,
        'before':baseline,'after':final,'area_ratio':after.area/before.area}

metadata={'classification':'optical correction of CC0 illustration; not measured from the perspective photograph',
    'czech_tangent_scale':TANGENT_SCALE,'czech_radial_scale':1,
    'czech_positions_unchanged':True,'czech_source_path_strings_unchanged':True,
    'czech_group_centers':ring_metadata,'curve_flattening_tolerance':CURVE_TOLERANCE,
    'zodiac_fill':GLYPH_FILL,'zodiac_fill_classification':'optical color adjustment; not measured from the photograph',
    'zodiac':zodiac_metadata,'source_reference':'audit/evidence/12-reference-2019.jpg',
    'app_comparison':'audit/2026-09-26-materials/ipad-portrait.png'}
(HERE/'refined-lettering-metadata.json').write_text(json.dumps(metadata,indent=2)+'\n')
print(json.dumps({name:{'inset':v['applied_inset'],'area_ratio':round(v['area_ratio'],3),'components':v['after']['components'],'holes':v['after']['holes']} for name,v in zodiac_metadata.items()},indent=2))
