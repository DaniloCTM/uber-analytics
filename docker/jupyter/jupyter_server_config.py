import os
from jupyter_server.auth import passwd


password = os.getenv("JUPYTER_PASSWORD", "")

c = get_config()

if password:
    c.ServerApp.password = passwd(password) 
else:
    c.ServerApp.password = ""

c.ServerApp.token = ''          
c.ServerApp.allow_origin = '*'   
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
