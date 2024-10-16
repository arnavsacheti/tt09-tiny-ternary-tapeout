FLOW = --openlane2
TOOL = ./tt/tt_tool.py

INFO_DIR = gds

all: gds info

debug: 
	$(TOOL) --debug --create-user-config $(FLOW)
	$(TOOL) --debug --harden $(FLOW)

gds:
	$(TOOL) --create-user-config $(FLOW)
	$(TOOL) --harden $(FLOW)

info:
	mkdir $(INFO_DIR)
	$(TOOL) --print-stats $(FLOW) > $(INFO_DIR)/stats.txt
	$(TOOL) --print-cell-summary $(FLOW) > $(INFO_DIR)/cell-summary.txt
	$(TOOL) --print-cell-category $(FLOW) > $(INFO_DIR)/cell-category.txt

clean:
	rm -rf runs $(INFO_DIR) src/config_merged.json src/user_config.json