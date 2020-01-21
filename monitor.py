#!/usr/bin/env python3

import signal
import time
import os
import subprocess
import json
from urllib3.exceptions import ReadTimeoutError
from enum import Flag, auto

STORAGEOS_BIN = '/storageos'
MANDATORY_ENV_VARS = ['NODE_NAME', 'STORAGEOS_BIN', 'STORAGEOS_USERNAME', 'STORAGEOS_PASSWORD', 'STORAGEOS_HOST']

from kubernetes import client, config, watch


class DaemonState(Flag):
    RUNNING = auto()
    SHOULD_CLOSE = auto()
    MUST_CLOSE = auto()

class StorageOS:
    storageos_bin = None
    node_name = None
    def __init__(self, node_name: str, storageos_bin: str = None):
        self.node_name = node_name
        self.storageos_bin = storageos_bin

    def _run(self, args, **kwargs):
        print('exec: {} ({})'.format(' '.join(args), kwargs))
        return subprocess.run([self.storageos_bin] + args, **kwargs)

    def _run_json(self, args, **kwargs):
        return json.loads(self._run(args, capture_output=True, text=True, **kwargs).stdout)

    def _wait_for_cordon(self):
        self._run(['node', 'cordon', self.node_name])
        info = {'cordon': False}
        while info['cordon'] == False:
            time.sleep(1)
            info = self._run_json(['node', 'inspect', self.node_name])[0]

    def wait_for_drain(self, daemon):
        self._wait_for_cordon()
        self._run(['node', 'drain', self.node_name])
        info = {'drain': False, 'volumeStats': {}}
        while (info['drain'] == False or sum([v for _, v in info['volumeStats'].items()]) != 0) and daemon.state != DaemonState.MUST_CLOSE:
            time.sleep(1)
            info = self._run_json(['node', 'inspect', self.node_name])[0]

    def wait_for_uncordon(self):
        self._wait_for_undrain()
        self._run(['node', 'uncordon', self.node_name])
        info = {'cordon': True}
        while info['cordon'] == True:
            time.sleep(1)
            info = self._run_json(['node', 'inspect', self.node_name])[0]

    def _wait_for_undrain(self):
        self._run(['node', 'undrain', self.node_name])
        info = {'drain': True}
        while info['drain'] == True:
            time.sleep(1)
            info = self._run_json(['node', 'inspect', self.node_name])[0]

    def delete_node(self, node_name):
        self._run(['node', 'delete', node_name])

class GracefulKiller:
    state = DaemonState.RUNNING
    def __init__(self):
        signal.signal(signal.SIGINT, self.exit_gracefully)
        signal.signal(signal.SIGTERM, self.start_shuting_down)

    def start_shuting_down(self, signum, frame):
        print("I should stop now.")
        self.state = DaemonState.SHOULD_CLOSE

    def exit_gracefully(self, signum, frame):
        print("I really must stop now !")
        self.state = DaemonState.MUST_CLOSE

if __name__ == '__main__':
    missing_vars = [var for var in MANDATORY_ENV_VARS if var not in os.environ]
    if len(missing_vars):
        print('missing environment variables: {}'.format(','.join(missing_vars)))
        time.sleep(5)
        os.sys.exit(1)
    storageos = StorageOS(os.environ['NODE_NAME'], os.environ['STORAGEOS_BIN'])
    storageos.wait_for_uncordon()

    print("installing SIGINT and SIGTERM handlers")
    killer = GracefulKiller()
    print("waiting to be drained ...")

    # Configs can be set in Configuration class directly or using helper utility
    if 'KUBECONFIG' in os.environ:
        print('loading config from KUBECONFIG ({})'.format(os.environ['KUBECONFIG']))
        config.load_kube_config()
    else:
        print('loading config from within the cluster')
        config.load_incluster_config()

    v1 = client.CoreV1Api()
    w = watch.Watch()
    while killer.state == DaemonState.RUNNING:
        try:
            for event in w.stream(v1.list_node, timeout_seconds=3):
                print("Event: %s %s" % (event['type'], event['object'].metadata.name))
                # Event: ADDED b2-7.1
                # Event: MODIFIED b2-7.2
                # Event: DELETED b2-7.1
                if event['type'].lower() == "deleted":
                    storageos.delete_node(event['object'].metadata.name)
        except ReadTimeoutError as ex:
            pass
    w.stop()
    storageos.wait_for_drain(killer)
    print("End of the program. I was killed gracefully :)")
