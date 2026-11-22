#!/usr/bin/env bash
# zed's visual QA capture on gs-game's shot tool (gs-game docs/visual-qa.md): first person | behind-right | opponent, per
# weapon and clip. gpu.sh runs only tools/*.sh.
#   tools/zed_vqa_shot.sh [--only uzi,sawed_off] [--clips hip,fire,reload,aim,draw] [--out DIR] [--fps 30] [--clip-dir DIR]
exec bash "$(dirname "$0")/../addons/gs_game/tools/gs_game_visual_qa_shot.sh" --script tools/zed_vqa.gd -- "$@"
