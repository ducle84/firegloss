import subprocess
import sys
import os

def start_server():
    print('Starting FireGloss Backend Server...')
    print('Server will be available at: http://127.0.0.1:8000')
    print('API documentation at: http://127.0.0.1:8000/docs')
    print('Press Ctrl+C to stop the server')
    print('-' * 50)
    
    try:
        subprocess.run([sys.executable, 'main.py'])
    except KeyboardInterrupt:
        print('\\nServer stopped.')

if __name__ == '__main__':
    start_server()
