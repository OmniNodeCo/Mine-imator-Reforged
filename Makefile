# Mine-imator Reforged convenience targets (macOS/Linux).
# On Windows, call Setup.ps1 / the Tools scripts directly (see BUILD.md).
#   make assets [RANGE=1.21:26.3] [LATEST=1]   fetch + package Minecraft assets
#   make check                                  asset pipeline self-test
#   make cppgen                                 regenerate C++ from GML
#   make release                                full release build into install/

RANGE ?= 1.21:26.3
LATEST ?= 1
OUT ?= GmProject/datafiles/Data/Minecraft

ifeq ($(LATEST),1)
LATEST_FLAG := --latest
else
LATEST_FLAG :=
endif

.PHONY: help assets check cppgen release

help:
	@echo "Targets: assets [RANGE=.. LATEST=0/1 OUT=..] | check | cppgen | release"

assets:
	python3 Tools/fetch_minecraft_assets.py --range "$(RANGE)" $(LATEST_FLAG) --out "$(OUT)"

check:
	python3 Tools/fetch_minecraft_assets.py --self-test

cppgen:
	./Setup.sh CppGen

release:
	./Setup.sh Release
