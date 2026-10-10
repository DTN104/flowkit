#!/usr/bin/env bash
# Flow Kit — start agent with the pinned Flow project
cd "$(dirname "$0")"
export FLOW_PROJECT_ID=42222b49-988f-497b-af31-fa393740e4a2
export TTS_PYTHON_BIN="$PWD/tts-venv/bin/python3"
source venv/bin/activate
python -m agent.main
