#!/usr/bin/env python3
"""Патч для исправления бага в gradio_client/utils.py"""

import sys

def patch_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    patched_lines = []
    get_type_patched = False
    json_schema_patched = False
    in_get_type = False
    in_json_schema = False
    
    for i, line in enumerate(lines):
        # Патчим get_type
        if 'def get_type(schema' in line and not get_type_patched:
            in_get_type = True
            patched_lines.append(line)
            continue
        
        if in_get_type and not get_type_patched and line.strip() and not line.strip().startswith('#'):
            indent = len(line) - len(line.lstrip())
            patched_lines.append(' ' * indent + 'if not isinstance(schema, dict):')
            patched_lines.append(' ' * indent + '    return "any"')
            get_type_patched = True
            in_get_type = False
        
        # Патчим _json_schema_to_python_type
        if 'def _json_schema_to_python_type(schema' in line and not json_schema_patched:
            in_json_schema = True
            patched_lines.append(line)
            continue
        
        if in_json_schema and not json_schema_patched and line.strip() and not line.strip().startswith('#'):
            indent = len(line) - len(line.lstrip())
            patched_lines.append(' ' * indent + '# Handle boolean schemas (True = any, False = never)')
            patched_lines.append(' ' * indent + 'if isinstance(schema, bool):')
            patched_lines.append(' ' * indent + '    return "any"')
            json_schema_patched = True
            in_json_schema = False
        
        patched_lines.append(line)
    
    if not get_type_patched:
        print("Предупреждение: не удалось найти функцию get_type для патча", file=sys.stderr)
        return False
    
    if not json_schema_patched:
        print("Предупреждение: не удалось найти функцию _json_schema_to_python_type для патча", file=sys.stderr)
        return False
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(patched_lines))
    
    print(f"Файл {filepath} успешно пропатчен (get_type + _json_schema_to_python_type)")
    return True

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Использование: {sys.argv[0]} <путь_к_utils.py>")
        sys.exit(1)
    
    filepath = sys.argv[1]
    success = patch_file(filepath)
    sys.exit(0 if success else 1)
