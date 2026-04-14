#!/bin/sh

claude --dangerously-skip-permissions --continue "$@" 2>/dev/null || claude --dangerously-skip-permissions "$@"
