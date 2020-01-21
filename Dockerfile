FROM python:3-alpine

#RUN apk add build-base

COPY storageos /
ENV STORAGEOS_BIN /storageos

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY monitor.py /

ENTRYPOINT ["/monitor.py"]
