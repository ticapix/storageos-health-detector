FROM k8s.gcr.io/node-problem-detector:v0.8.0

COPY config/ /config/
COPY storageos /

ENTRYPOINT ["/node-problem-detector", "--logtostderr", \
    "--config.custom-plugin-monitor=/config/storageos-monitor.json", \
    "--enable-k8s-exporter", "true", \
    "--apiserver-wait-timeout", "30s"]
