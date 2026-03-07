#!/bin/bash
GIT_REPO=$(git remote -v | head -n 1 | awk '{print $2}')

function clone_feature {
    if [ ! `git branch --list $1` ]; then
        echo "Couldn't find branch $1"
    else
        git submodule add -b $1 ${GIT_REPO} features/$2 
    fi
}

clone_feature feature/alu alu
clone_feature feature/id id
clone_feature feature/imem imem
clone_feature feature/pc pc
clone_feature feature/cpu cpu
clone_feature feature/branch_unit branch_unit
clone_feature feature/imm_gen imm_gen
clone_feature register_file rf
