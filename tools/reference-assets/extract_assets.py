#!/usr/bin/env python3
"""Extract authored CC0 vector shapes. Python standard library only.

Run from any directory. The original downloaded SVG and glyph-metadata.json
must be beside this script. No glyph outlines are redrawn or font substituted.
"""
from pathlib import Path
import copy
import hashlib
import json
import math
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
ASSETS = REPO / 'astologia hologia' / 'Assets.xcassets'
SOURCE = HERE / 'Prague_Astronomical_Clock.svg'
SOURCE_SHA256 = 'd010d122838a1f12ab197936942e59e8fa0080830baf64f97dac3e51e9ba20c7'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == SOURCE_SHA256
SVG = 'http://www.w3.org/2000/svg'
ET.register_namespace('', SVG)
root = ET.parse(SOURCE).getroot()
source_group = root.find('.//*[@id="g4491"]')


def clean(element):
    """Keep geometry, paint and transforms; discard editor-only metadata."""
    result = copy.deepcopy(element)
    for node in result.iter():
        node.attrib = {k: v for k, v in node.attrib.items() if not k.startswith('{')}
        if 'style' in node.attrib:
            styles = dict(item.split(':', 1) for item in node.attrib['style'].split(';') if ':' in item)
            keep = ('fill', 'fill-opacity', 'fill-rule', 'stroke', 'stroke-width', 'stroke-opacity', 'stroke-linejoin', 'stroke-linecap', 'opacity')
            node.set('style', ';'.join(f'{k}:{styles[k]}' for k in keep if k in styles))
    return result


def svg(size=1024):
    return ET.Element(f'{{{SVG}}}svg', width=str(size), height=str(size), viewBox=f'0 0 {size} {size}')


def group(parent, transform):
    return ET.SubElement(parent, f'{{{SVG}}}g', transform=transform)


def write_asset(name, document):
    folder = ASSETS / f'{name}.imageset'
    folder.mkdir(parents=True, exist_ok=True)
    ET.indent(document)
    ET.ElementTree(document).write(folder / f'{name}.svg', encoding='utf-8', xml_declaration=True)
    (folder / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': f'{name}.svg', 'idiom': 'universal'}],
        'info': {'author': 'xcode', 'version': 1},
        'properties': {'preserves-vector-representation': True}
    }, indent=2) + '\n')


# Source face center/radius derive from its outer circular frame, path4371.
# The clockwise angle is measured from screen-up. 24 is g4940.
center = (980.32275, -192.64893)
outer_radius = 54.737357  # frame radius 54.237357 + half its 1-unit stroke
angle24 = 102.41624192031011
ring = svg()
normalized = group(ring, f'translate(512 512) scale({512 / outer_radius:.12f}) rotate({-angle24:.12f}) translate({-center[0]} {-center[1]})')
outer_ids = []
for child in source_group:
    if any('fill:#efdd9a' in p.get('style', '') for p in child.iter()):
        normalized.append(clean(child))
        outer_ids.append(child.get('id'))
assert len(outer_ids) == 24
write_asset('historic_czech_numerals', ring)

# The outlined source symbols are already rotated around the source zodiac.
# Undo only their source orientation, then fit each into the same square.
# Bounds are analytical Bézier/arc bounds precomputed with svgpathtools 1.7.2.
# Original d data remain intact in every output, under affine transforms.
glyphs = json.loads((HERE / 'glyph-metadata.json').read_text())
for name, spec in glyphs.items():
    glyph = svg(128)
    x0, x1, y0, y1 = spec['rotated_bounds']
    scale = 112 / max(x1 - x0, y1 - y0)
    cx, cy = spec['rotation_center']
    g = group(glyph, f'translate(64 64) scale({scale:.12f}) translate({-(x0 + x1) / 2:.12f} {-(y0 + y1) / 2:.12f}) rotate({spec["rotation_degrees"]:.12f} {cx:.12f} {cy:.12f})')
    g.append(clean(root.find(f'.//*[@id="{spec["id"]}"]')))
    write_asset(f'historic_zodiac_{name}', glyph)

# Globe paint beneath the mobile mechanism: ocean disk and three continent paths.
earth = svg(256)
earth_radius = 13.369622  # circle radius 13.119622 + half its 0.5-unit outline
ge = group(earth, f'translate(128 128) scale({128 / earth_radius:.12f}) translate({-center[0]} {-center[1]})')
for source_id in ('path4441', 'path13662', 'path13664', 'path13670'):
    ge.append(clean(root.find(f'.//*[@id="{source_id}"]')))
write_asset('historic_earth', earth)

placement = {
    'source_sha256': SOURCE_SHA256,
    'source_face_center': list(center),
    'source_outer_frame_radius_including_stroke': outer_radius,
    'czech_numerals': {
        'asset': 'historic_czech_numerals', 'view_box': [0, 0, 1024, 1024],
        'center': [512, 512], 'reference_outer_radius': 512,
        'numeral_24_angle_degrees_clockwise_from_top': 0,
        'source_numeral_24_angle_degrees_clockwise_from_top': angle24,
        'approximate_numeral_center_radius': 474,
        'rotation_to_apply': 'state.sunsetAngleDegrees, when this state angle is clockwise from screen-up',
        'source_top_level_ids': outer_ids
    },
    'earth': {
        'asset': 'historic_earth', 'view_box': [0, 0, 256, 256], 'center': [128, 128],
        'source_radius_including_stroke': earth_radius,
        'source_earth_to_outer_frame_radius_ratio': earth_radius / outer_radius,
        'source_earth_to_equator_radius_ratio': earth_radius / 28.786131,
        'layering': 'fixed to plate, beneath all moving hands and center axle'
    },
    'zodiac': {
        'names': list(glyphs), 'view_box': [0, 0, 128, 128],
        'maximum_ink_dimension': 112,
        'orientation': 'source local radial orientation removed; apply app ecliptic tangent orientation at rendering time',
        'details': glyphs
    }
}
(HERE / 'placement.json').write_text(json.dumps(placement, indent=2) + '\n')
print('Extracted 24 numerals in one transparent ring, 12 zodiac glyphs, and the fixed Earth globe.')
