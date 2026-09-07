"""Read-only SLX extraction for GitHub/AI inspection; never modifies models."""
from pathlib import Path
import hashlib
import zipfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
lines = ['# Model text index', '', 'Generated from current SLX files. XML is read-only derived evidence.', '']
for model in ('PMLSM_MIL_ControlCore_Sim', 'PMLSM_ControlCore_Block'):
    src = root / (model + '.slx')
    lines += ['## ' + model, '', 'SHA256: `' + hashlib.sha256(src.read_bytes()).hexdigest() + '`', '', '| XML | SID | Name | Type |', '|---|---|---|---|']
    with zipfile.ZipFile(src) as archive:
        for name in sorted(archive.namelist()):
            if not name.startswith('simulink/') or not name.endswith('.xml'):
                continue
            relative = Path(name)
            assert '..' not in relative.parts and not relative.is_absolute()
            destination = root / 'docs/model_source' / model / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            payload = archive.read(name)
            destination.write_bytes(payload)
            if name.startswith('simulink/systems/'):
                for block in ET.fromstring(payload).iter('Block'):
                    def escape(value):
                        return (value or '').replace('|', '&#124;').replace('\n', ' ')
                    lines.append('| ' + ' | '.join(escape(v) for v in (name, block.get('SID'), block.get('Name'), block.get('BlockType'))) + ' |')
    lines.append('')
(root / 'docs/model_index.md').write_text('\n'.join(lines), encoding='utf-8')
print('Model XML and index exported.')
