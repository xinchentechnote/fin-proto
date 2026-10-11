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
	$(BIN_DIR)/fin-protoc -f risk/risk_v0.1.0.pdsl -l risk/
	$(BIN_DIR)/fin-protoc -f sse/binary/sse_bin_v0.57.pdsl -l sse/binary/
	$(BIN_DIR)/fin-protoc -f szse/binary/szse_bin_v1.29.pdsl -l szse/binary/
	$(BIN_DIR)/fin-protoc -f bist/bist_itch_v2112.pdsl -l bist/
	$(BIN_DIR)/fin-protoc -f nasdaq/ouch_v5.0.pdsl -l nasdaq/
	$(BIN_DIR)/fin-protoc -f nasdaq/rashport_v1.1.pdsl -l nasdaq/
	$(BIN_DIR)/fin-protoc -f nyse/nyse_pillar_bin_v5.15.pdsl -l nyse/
	$(BIN_DIR)/fin-protoc -f nyse/nyse_pillar_options_bin_v3.24.pdsl -l nyse/
	$(BIN_DIR)/fin-protoc -f lse/turquoise/tq301_native_v5.0.1.pdsl -l lse/turquoise/
	$(BIN_DIR)/fin-protoc -f its/its_native_v1.1.2.pdsl -l its/
	@echo "Skip (needs STEP syntax): szse/step/szse_step_v1.29.pdsl sse/step/sse_step_v0.57.pdsl"
