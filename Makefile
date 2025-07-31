# Makefile for fin-protoc project

# Variables
BIN_DIR := ~/workspace/fin-protoc/bin/

.PHONY: all compile

all: compile

build: compile

compile:
	@echo "Compiling protocol..."
	$(BIN_DIR)/fin-protoc -f bse/bse_trade_bin_v0.9.pdsl -l bse/
	$(BIN_DIR)/fin-protoc -f bse/bse_md_bin_v0.9.pdsl -l bse/
	$(BIN_DIR)/fin-protoc -f sample/sample.pdsl -l sample/
	$(BIN_DIR)/fin-protoc -f risk/risk_v0.1.0.dsl -l risk/
	$(BIN_DIR)/fin-protoc -f sse/binary/sse_bin_v0.57.pdsl -l sse/binary/
	$(BIN_DIR)/fin-protoc -f szse/binary/szse_bin_v1.29.pdsl -l szse/binary/
