@echo off
setlocal enabledelayedexpansion

:: Получаем URL удаленного репозитория
for /f "tokens=2" %%a in ('git remote -v ^| findstr /i "fetch"') do (
    set GIT_REPO=%%a
    goto :repo_found
)
:repo_found

echo Git репозиторий: %GIT_REPO%

:: Добавляем подмодули
git submodule add -b feature/alu %GIT_REPO% features/alu
git submodule add -b feature/id %GIT_REPO% features/id
git submodule add -b feature/imem %GIT_REPO% features/imem
git submodule add -b feature/pc %GIT_REPO% features/pc
git submodule add -b register_file %GIT_REPO% features/rf

echo Готово.