#!/usr/bin/env python3
"""Exercise the executable without a running simulator or Android SDK."""
import json
import subprocess
import sys

binary = sys.argv[1]

def run(*args):
    return subprocess.run([binary, *args], text=True, capture_output=True, timeout=10)

assert run('--version').returncode == 0
assert 'location' in run('--help').stdout
for args in [('cli', 'boot'), ('cli', 'unknown'), ('cli', 'location', 'x', '91', '0')]:
    assert run(*args).returncode != 0, args
invalid = run('cli', 'location', 'x', 'nan', '0', '--json')
assert invalid.returncode == 1
assert json.loads(invalid.stdout)['success'] is False
# Dispatch uses the first argument, so values containing "mcp" or "cli" cannot change modes.
assert run('unknown', 'mcp').returncode == 2
messages = [
    '{bad json',
    json.dumps({'jsonrpc': '2.0', 'id': 'init', 'method': 'initialize', 'params': {'protocolVersion': '2025-06-18'}}),
    json.dumps({'jsonrpc': '2.0', 'method': 'notifications/initialized'}),
    json.dumps({'jsonrpc': '2.0', 'id': 0, 'method': 'ping'}),
    json.dumps({'jsonrpc': '2.0', 'id': 2, 'method': 'tools/list'}),
    json.dumps({'jsonrpc': '2.0', 'id': 3, 'method': 'tools/call', 'params': {'name': 'devbar_set_location', 'arguments': {'id': 'x', 'latitude': True, 'longitude': 0}}}),
]
process = subprocess.run([binary, 'mcp'], input='\n'.join(messages)+'\n', text=True, capture_output=True, timeout=10)
assert process.returncode == 0, process.stderr
responses = [json.loads(line) for line in process.stdout.splitlines()]
assert len(responses) == 5
assert responses[0]['error']['code'] == -32700
assert responses[1]['id'] == 'init'
assert responses[2]['id'] == 0
assert len(responses[3]['result']['tools']) == 9
assert responses[4]['error']['code'] == -32602
print('CLI and MCP smoke checks passed.')
