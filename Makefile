FLOW = --openlane2
TOOL = ./tt/tt_tool.py

INFO_DIR = info
FINAL_DIR = runs/wokwi/final
TEST_DIR = test

all:

debug: 
	$(TOOL) --debug --create-user-config $(FLOW)
	$(TOOL) --debug --harden $(FLOW)

gds: src/*.v
	$(TOOL) --create-user-config $(FLOW)
	$(TOOL) --harden $(FLOW)

gl: gds
	cp $(FINAL_DIR)/pnl/*.v $(TEST_DIR)/gate_level_netlist.v
	cd $(TEST_DIR); make clean; GATES=yes make; cd ..

info:
	mkdir -p $(INFO_DIR)
	$(TOOL) --print-stats $(FLOW) > $(INFO_DIR)/stats.txt
	$(TOOL) --print-cell-summary $(FLOW) > $(INFO_DIR)/cell-summary.txt
	$(TOOL) --print-cell-category $(FLOW) > $(INFO_DIR)/cell-category.txt

clean: runs/*
	rm -rf runs $(INFO_DIR) src/config_merged.json src/user_config.json