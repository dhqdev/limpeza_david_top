#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
limpeza_david - API REST para o Frontend React
Autor: David Fernandes
Descrição: API Flask que expõe endpoints para scan, limpeza e atualização.
"""

import os
import sys
import platform
import subprocess
import threading
from pathlib import Path
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS

# Adiciona o diretório pai ao path para imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.utils import format_size, get_logger

# Importa o cleaner apropriado baseado no SO
if platform.system() == 'Windows':
    from app.cleaner.windows import WindowsCleaner as SystemCleaner
else:
    from app.cleaner.linux import LinuxCleaner as SystemCleaner


# Configuração - Caminho absoluto para o diretório dist do frontend
BASE_DIR = Path(__file__).parent.parent
FRONTEND_DIST = BASE_DIR / 'frontend' / 'dist'

app = Flask(__name__, static_folder=str(FRONTEND_DIST), static_url_path='')
CORS(app)

# Inicializa o cleaner
cleaner = SystemCleaner()
logger = get_logger("API")

# Estado global da aplicação
app_state = {
    'is_scanning': False,
    'is_cleaning': False,
    'is_updating': False,
    'scan_results': {},
    'progress': 0,
    'status': 'idle',
    'current_task': '',
    'logs': []
}


def add_log(message, level='info'):
    """Adiciona uma mensagem ao log."""
    app_state['logs'].append({
        'message': message,
        'level': level
    })
    # Mantém apenas os últimos 100 logs
    if len(app_state['logs']) > 100:
        app_state['logs'] = app_state['logs'][-100:]


@app.route('/')
def index():
    """Serve o frontend React."""
    return send_from_directory(app.static_folder, 'index.html')


@app.route('/assets/<path:filename>')
def serve_frontend_assets(filename):
    """Serve arquivos de assets do frontend (JS, CSS)."""
    return send_from_directory(str(FRONTEND_DIST / 'assets'), filename)


@app.route('/api/system-info')
def get_system_info():
    """Retorna informações do sistema."""
    return jsonify({
        'system': platform.system(),
        'release': platform.release(),
        'version': '1.0.0'
    })


@app.route('/api/categories')
def get_categories():
    """Retorna as categorias de limpeza disponíveis."""
    categories = cleaner.get_categories()
    return jsonify(categories)


@app.route('/api/state')
def get_state():
    """Retorna o estado atual da aplicação."""
    return jsonify({
        'is_scanning': app_state['is_scanning'],
        'is_cleaning': app_state['is_cleaning'],
        'is_updating': app_state['is_updating'],
        'progress': app_state['progress'],
        'status': app_state['status'],
        'current_task': app_state['current_task'],
        'logs': app_state['logs'][-20:]  # Últimos 20 logs
    })


@app.route('/api/scan', methods=['POST'])
def start_scan():
    """Inicia a análise do sistema."""
    if app_state['is_scanning'] or app_state['is_cleaning']:
        return jsonify({'error': 'Operação já em andamento'}), 400
    
    data = request.get_json()
    categories = data.get('categories', [])
    
    if not categories:
        return jsonify({'error': 'Selecione pelo menos uma categoria'}), 400
    
    # Inicia scan em thread separada
    thread = threading.Thread(target=scan_thread, args=(categories,))
    thread.daemon = True
    thread.start()
    
    return jsonify({'message': 'Análise iniciada'})


def scan_thread(categories):
    """Thread de análise."""
    try:
        app_state['is_scanning'] = True
        app_state['status'] = 'scanning'
        app_state['progress'] = 0
        app_state['scan_results'] = {}
        app_state['logs'] = []
        
        add_log('🔍 Iniciando análise do sistema...', 'header')
        
        total_size = 0
        total_files = 0
        all_categories = cleaner.get_categories()
        
        for i, cat_id in enumerate(categories):
            progress = ((i + 1) / len(categories)) * 100
            app_state['progress'] = progress
            
            cat_info = all_categories.get(cat_id, {})
            cat_name = cat_info.get('name', cat_id)
            
            app_state['current_task'] = f"Analisando: {cat_name}"
            add_log(f'📂 Analisando: {cat_name}...', 'info')
            
            # Escaneia a categoria
            files, size = cleaner.scan_category(cat_id)
            
            app_state['scan_results'][cat_id] = {
                'files': files,
                'size': size,
                'name': cat_name
            }
            
            total_size += size
            total_files += len(files)
            
            add_log(f'  └─ {len(files)} arquivos ({format_size(size)})', 'success')
        
        add_log('', 'info')
        add_log('═' * 40, 'header')
        add_log(f'📊 RESUMO DA ANÁLISE:', 'header')
        add_log(f'   Total de arquivos: {total_files}', 'success')
        add_log(f'   Espaço a liberar: {format_size(total_size)}', 'success')
        add_log('═' * 40, 'header')
        
        app_state['status'] = 'scan_complete'
        app_state['current_task'] = ''
        app_state['progress'] = 100
        
        if total_files > 0:
            add_log('', 'info')
            add_log('✅ Clique em "Limpar" para remover os arquivos.', 'info')
        else:
            add_log('', 'info')
            add_log('✨ Sistema já está limpo!', 'success')
            
    except Exception as e:
        add_log(f'❌ Erro durante análise: {str(e)}', 'error')
        logger.error(f"Erro na análise: {e}")
        app_state['status'] = 'error'
    finally:
        app_state['is_scanning'] = False


@app.route('/api/scan-results')
def get_scan_results():
    """Retorna os resultados da última análise."""
    results = app_state['scan_results']
    
    total_files = sum(len(r['files']) for r in results.values())
    total_size = sum(r['size'] for r in results.values())
    
    return jsonify({
        'results': {
            cat_id: {
                'name': data['name'],
                'file_count': len(data['files']),
                'size': data['size'],
                'size_formatted': format_size(data['size'])
            }
            for cat_id, data in results.items()
        },
        'total_files': total_files,
        'total_size': total_size,
        'total_size_formatted': format_size(total_size)
    })


@app.route('/api/clean', methods=['POST'])
def start_clean():
    """Inicia a limpeza dos arquivos."""
    if app_state['is_scanning'] or app_state['is_cleaning']:
        return jsonify({'error': 'Operação já em andamento'}), 400
    
    if not app_state['scan_results']:
        return jsonify({'error': 'Faça uma análise primeiro'}), 400
    
    # Inicia limpeza em thread separada
    thread = threading.Thread(target=clean_thread)
    thread.daemon = True
    thread.start()
    
    return jsonify({'message': 'Limpeza iniciada'})


def clean_thread():
    """Thread de limpeza."""
    try:
        app_state['is_cleaning'] = True
        app_state['status'] = 'cleaning'
        app_state['progress'] = 0
        
        add_log('', 'info')
        add_log('🗑️ Iniciando limpeza...', 'header')
        
        total_removed = 0
        total_size_freed = 0
        total_errors = 0
        
        categories = list(app_state['scan_results'].keys())
        all_categories = cleaner.get_categories()
        
        for i, cat_id in enumerate(categories):
            progress = ((i + 1) / len(categories)) * 100
            app_state['progress'] = progress
            
            result = app_state['scan_results'][cat_id]
            files = result['files']
            cat_name = result['name']
            
            if not files:
                continue
            
            app_state['current_task'] = f"Limpando: {cat_name}"
            add_log(f'🧹 Limpando: {cat_name}...', 'info')
            
            # Remove os arquivos
            removed, size_freed, errors = cleaner.clean_files(files)
            
            total_removed += removed
            total_size_freed += size_freed
            total_errors += errors
            
            add_log(f'  └─ {removed} removidos ({format_size(size_freed)})', 'success')
            if errors > 0:
                add_log(f'  └─ {errors} erros (arquivos em uso)', 'warning')
        
        add_log('', 'info')
        add_log('═' * 40, 'header')
        add_log('✅ LIMPEZA CONCLUÍDA!', 'header')
        add_log(f'   Arquivos removidos: {total_removed}', 'success')
        add_log(f'   Espaço liberado: {format_size(total_size_freed)}', 'success')
        if total_errors > 0:
            add_log(f'   Erros: {total_errors}', 'warning')
        add_log('═' * 40, 'header')
        
        app_state['status'] = 'clean_complete'
        app_state['current_task'] = ''
        app_state['progress'] = 100
        app_state['scan_results'] = {}
        
    except Exception as e:
        add_log(f'❌ Erro durante limpeza: {str(e)}', 'error')
        logger.error(f"Erro na limpeza: {e}")
        app_state['status'] = 'error'
    finally:
        app_state['is_cleaning'] = False


@app.route('/api/update', methods=['POST'])
def start_update():
    """Executa git pull para atualizar a aplicação."""
    if app_state['is_updating']:
        return jsonify({'error': 'Atualização já em andamento'}), 400
    
    # Inicia atualização em thread separada
    thread = threading.Thread(target=update_thread)
    thread.daemon = True
    thread.start()
    
    return jsonify({'message': 'Atualização iniciada'})


def update_thread():
    """Thread de atualização."""
    try:
        app_state['is_updating'] = True
        app_state['status'] = 'updating'
        app_state['current_task'] = 'Atualizando aplicação...'
        
        add_log('', 'info')
        add_log('🔄 Verificando atualizações...', 'header')
        
        # Encontra o diretório do projeto
        project_dir = Path(__file__).parent.parent
        
        # Executa git pull
        result = subprocess.run(
            ['git', 'pull'],
            cwd=project_dir,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode == 0:
            output = result.stdout.strip()
            if 'Already up to date' in output or 'Já está atualizado' in output:
                add_log('✅ Aplicação já está atualizada!', 'success')
            else:
                add_log('✅ Atualização concluída!', 'success')
                add_log(f'   {output}', 'info')
        else:
            add_log(f'⚠️ Erro na atualização: {result.stderr}', 'warning')
        
        app_state['status'] = 'idle'
        app_state['current_task'] = ''
        
    except subprocess.TimeoutExpired:
        add_log('❌ Tempo esgotado durante atualização', 'error')
        app_state['status'] = 'error'
    except Exception as e:
        add_log(f'❌ Erro na atualização: {str(e)}', 'error')
        logger.error(f"Erro na atualização: {e}")
        app_state['status'] = 'error'
    finally:
        app_state['is_updating'] = False


@app.route('/api/clear-logs', methods=['POST'])
def clear_logs():
    """Limpa os logs."""
    app_state['logs'] = []
    return jsonify({'message': 'Logs limpos'})


# Serve arquivos de imagens da pasta assets do projeto (icon.png)
@app.route('/img/<path:filename>')
def serve_project_assets(filename):
    """Serve arquivos da pasta assets do projeto (imagens)."""
    assets_dir = BASE_DIR / 'assets'
    return send_from_directory(str(assets_dir), filename)


def run_api(host='0.0.0.0', port=5000, debug=False):
    """Inicia o servidor da API."""
    logger.info(f"Iniciando API em http://{host}:{port}")
    app.run(host=host, port=port, debug=debug, threaded=True)


if __name__ == '__main__':
    run_api(debug=True)
