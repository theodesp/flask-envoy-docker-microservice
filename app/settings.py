"""
Settings file, which is populated from the environment while enforcing common
use-case defaults.
"""
import os
from os.path import join, dirname
from dotenv import load_dotenv

dotenv_path = join(dirname(__file__), '.env')
load_dotenv(dotenv_path)

# OR, the same with increased verbosity:
load_dotenv(dotenv_path, verbose=True)

DEBUG = True
if os.getenv('DEBUG', '').lower() in ['0', 'no', 'false']:
    DEBUG = False

API_BIND_HOST = os.getenv('SERVICE_API_HOST', '127.0.0.1')
API_BIND_PORT = int(os.getenv('SERVICE_API_PORT', 8080))
SERVICE_NAME = os.getenv('SERVICE_NAME', 'app')
