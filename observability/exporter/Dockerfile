FROM public.ecr.aws/docker/library/python:3.13-slim

WORKDIR /app

RUN pip install --no-cache-dir boto3==1.43.78

COPY exporter.py .

ENV PYTHONUNBUFFERED=1 \
    EXPORTER_PORT=9877 \
    POLL_INTERVAL=15

RUN useradd --create-home --shell /usr/sbin/nologin exporter

USER exporter

EXPOSE 9877

CMD ["python3", "exporter.py"]
