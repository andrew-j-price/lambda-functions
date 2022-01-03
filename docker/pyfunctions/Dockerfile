FROM python:3.8-bullseye

COPY ci-requirements.txt /ci-requirements.txt
RUN python -m pip install --no-cache-dir --upgrade pip && \
    python -m pip install --no-cache-dir -r /ci-requirements.txt
