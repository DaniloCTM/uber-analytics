FROM jupyter/base-notebook:latest

USER root

WORKDIR /home/jovyan/work

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar configuração da senha
COPY jupyter_server_config.py /home/jovyan/.jupyter/

EXPOSE 8888

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
USER $NB_UID