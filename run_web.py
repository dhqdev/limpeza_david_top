#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para executar o Limpeza David com interface Web (React)
Inicia a API Flask e abre o navegador automaticamente.
"""

import os
import sys
import webbrowser
import threading
import time

# Adiciona o diretório do projeto ao path
project_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_dir)

from app.api import run_api


def open_browser(port):
    """Abre o navegador após o servidor iniciar."""
    time.sleep(1.5)
    webbrowser.open(f'http://localhost:{port}')


if __name__ == "__main__":
    port = 5000
    
    print("=" * 50)
    print("🧹 Limpeza David - Interface Web")
    print("=" * 50)
    print(f"\n🌐 Iniciando servidor em http://localhost:{port}")
    print("📝 Pressione Ctrl+C para encerrar\n")
    
    # Abre o navegador em uma thread separada
    browser_thread = threading.Thread(target=open_browser, args=(port,))
    browser_thread.daemon = True
    browser_thread.start()
    
    # Inicia a API
    run_api(host='0.0.0.0', port=port, debug=False)
