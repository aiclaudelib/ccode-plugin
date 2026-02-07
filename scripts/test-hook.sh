#!/bin/bash
set -euo pipefail
# test-hook.sh — Test hook scripts with sample JSON input
# Runs a hook with sample input, analyzes exit codes and JSON output

# Usage
show_usage() {
  echo "Usage: $0 [options] <hook-script> <test-input.json>"
  echo ""
  echo "Options:"
  echo "  -h, --help      Show this help message"
  echo "  -v, --verbose   Show detailed execution information"
  echo "  -t, --timeout N Set timeout in seconds (default: 60)"
  echo ""
  echo "Examples:"
  echo "  $0 validate-bash.sh test-input.json"
  echo "  $0 -v -t 30 validate-write.sh write-input.json"
  echo ""
  echo "Create sample test input with:"
  echo "  $0 --create-sample <event-type>"
  echo ""
  echo "Event types: PreToolUse, PostToolUse, Stop, SubagentStop,"
  echo "  UserPromptSubmit, SessionStart, SessionEnd"
  exit 0
}

# Create sample input for a given event type
create_sample() {
  local event_type="$1"

  case "$event_type" in
    PreToolUse)
      cat <<'EOF'
{
  "session_id": "test-session",
  "transcript_path": "/tmp/transcript.txt",
  "cwd": "/tmp/test-project",
  "permission_mode": "ask",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/tmp/test.txt",
    "content": "Test content"
  }
}
EOF
      ;;
    PostToolUse)
      cat <<'EOF'
{
  "session_id": "test-session",
  "transcript_path": "/tmp/transcript.txt",
  "cwd": "/tmp/test-project",
  "permission_mode": "ask",
  "hook_event_name": "PostToolUse",
  "tool_name": "Bash",
  "tool_result": "Command executed successfully"
}
EOF
      ;;
    Stop|SubagentStop)
      cat <<'EOF'
{
  "session_id": "test-session",
  "transcript_path": "/tmp/transcript.txt",
  "cwd": "/tmp/test-project",
  "permission_mode": "ask",
  "hook_event_name": "Stop",
  "reason": "Task appears complete"
}
EOF
      ;;
    UserPromptSubmit)
      cat <<'EOF'
{
  "session_id": "test-session",
  "transcript_path": "/tmp/transcript.txt",
  "cwd": "/tmp/test-project",
  "permission_mode": "ask",
  "hook_event_name": "UserPromptSubmit",
  "user_prompt": "Test user prompt"
}
EOF
      ;;
    SessionStart|SessionEnd)
      cat <<'EOF'
{
  "session_id": "test-session",
  "transcript_path": "/tmp/transcript.txt",
  "cwd": "/tmp/test-project",
  "permission_mode": "ask",
  "hook_event_name": "SessionStart"
}
EOF
      ;;
    *)
      echo "Unknown event type: $event_type" >&2
      echo "Valid types: PreToolUse, PostToolUse, Stop, SubagentStop, UserPromptSubmit, SessionStart, SessionEnd" >&2
      exit 1
      ;;
  esac
}

# Check for jq (used for JSON validation and pretty-printing)
HAS_JQ=true
if ! command -v jq &>/dev/null; then
  HAS_JQ=false
fi

# Parse arguments
VERBOSE=false
TIMEOUT=60

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_usage
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -t|--timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    --create-sample)
      create_sample "$2"
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 2 ]]; then
  echo "Error: Missing required arguments" >&2
  echo "" >&2
  show_usage
fi

HOOK_SCRIPT="$1"
TEST_INPUT="$2"

# Validate inputs
if [[ ! -f "$HOOK_SCRIPT" ]]; then
  echo "Error: Hook script not found: $HOOK_SCRIPT" >&2
  exit 1
fi

RUN_CMD="$HOOK_SCRIPT"
if [[ ! -x "$HOOK_SCRIPT" ]]; then
  echo "Warning: Hook script is not executable, running with bash..." >&2
  RUN_CMD="bash $HOOK_SCRIPT"
fi

if [[ ! -f "$TEST_INPUT" ]]; then
  echo "Error: Test input not found: $TEST_INPUT" >&2
  exit 1
fi

# Validate test input JSON
if [[ "$HAS_JQ" == "true" ]]; then
  if ! jq empty "$TEST_INPUT" 2>/dev/null; then
    echo "Error: Test input is not valid JSON" >&2
    exit 1
  fi
fi

echo "Testing hook: $HOOK_SCRIPT"
echo "Input: $TEST_INPUT"
echo ""

if [[ "$VERBOSE" == "true" ]]; then
  echo "Input JSON:"
  if [[ "$HAS_JQ" == "true" ]]; then
    jq . "$TEST_INPUT"
  else
    cat "$TEST_INPUT"
  fi
  echo ""
fi

# Set up environment
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/tmp/test-project}"
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
export CLAUDE_ENV_FILE="${CLAUDE_ENV_FILE:-/tmp/test-env-$$}"

if [[ "$VERBOSE" == "true" ]]; then
  echo "Environment:"
  echo "  CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR"
  echo "  CLAUDE_PLUGIN_ROOT=$CLAUDE_PLUGIN_ROOT"
  echo "  CLAUDE_ENV_FILE=$CLAUDE_ENV_FILE"
  echo ""
fi

# Run the hook
echo "Running hook (timeout: ${TIMEOUT}s)..."
echo ""

start_time=$(date +%s)

set +e
output=$(timeout "$TIMEOUT" bash -c "cat '$TEST_INPUT' | $RUN_CMD" 2>&1)
exit_code=$?
set -e

end_time=$(date +%s)
duration=$((end_time - start_time))

# Analyze results
echo "----------------------------------------"
echo "Results:"
echo ""
echo "Exit Code: $exit_code"
echo "Duration: ${duration}s"
echo ""

case $exit_code in
  0)
    echo "PASS — Hook approved/succeeded"
    ;;
  2)
    echo "BLOCKED — Hook blocked/denied"
    ;;
  124)
    echo "TIMEOUT — Hook timed out after ${TIMEOUT}s"
    ;;
  *)
    echo "UNEXPECTED — Hook returned exit code: $exit_code"
    ;;
esac

echo ""
echo "Output:"
if [[ -n "$output" ]]; then
  echo "$output"
  echo ""

  # Try to parse as JSON
  if [[ "$HAS_JQ" == "true" ]] && echo "$output" | jq empty 2>/dev/null; then
    echo "Parsed JSON output:"
    echo "$output" | jq .
  fi
else
  echo "(no output)"
fi

# Check for environment file
if [[ -f "$CLAUDE_ENV_FILE" ]]; then
  echo ""
  echo "Environment file created:"
  cat "$CLAUDE_ENV_FILE"
  rm -f "$CLAUDE_ENV_FILE"
fi

echo ""
echo "----------------------------------------"

if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 2 ]]; then
  echo "Test completed successfully"
  exit 0
else
  echo "Test failed"
  exit 1
fi
