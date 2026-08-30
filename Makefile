.PHONY: help install backup validate clean init test uninstall

# Default target
.DEFAULT_GOAL := help

# Configuration
CLAUDE_CONFIG_DIR ?= $(HOME)/.config/claude
CODEX_CONFIG_DIR ?= $(HOME)/.codex
BACKUP_DIR ?= $(HOME)/.config/claude/backups
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)
SOURCE_DIR := ./claude
CODEX_SOURCE_FILE := ./.codex/config.toml

# TOML syntax check. Exits 2 when no parser is available (tomllib is stdlib only
# on Python 3.11+), 1 on a genuine parse error, so a missing parser is reported
# as "skipped" instead of "invalid TOML".
TOML_CHECK_PY := import importlib.util, sys; m = next((importlib.import_module(n) for n in ('tomllib', 'tomli') if importlib.util.find_spec(n)), None); sys.exit(2) if m is None else m.load(open(sys.argv[1], 'rb'))

# Colors for output
COLOR_RESET := \033[0m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[34m
COLOR_RED := \033[31m

help: ## Show this help message
	@echo "$(COLOR_BLUE)Claude Configuration Deployment$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_GREEN)Available targets:$(COLOR_RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_YELLOW)%-15s$(COLOR_RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(COLOR_GREEN)Configuration:$(COLOR_RESET)"
	@echo "  CLAUDE_CONFIG_DIR: $(CLAUDE_CONFIG_DIR)"
	@echo "  CODEX_CONFIG_DIR: $(CODEX_CONFIG_DIR)"
	@echo "  BACKUP_DIR: $(BACKUP_DIR)"

init: ## Create necessary directories
	@echo "$(COLOR_BLUE)Creating directories...$(COLOR_RESET)"
	@mkdir -p $(CLAUDE_CONFIG_DIR)
	@mkdir -p $(CODEX_CONFIG_DIR)
	@mkdir -p $(BACKUP_DIR)
	@mkdir -p logs
	@echo "$(COLOR_GREEN)✓ Directories created$(COLOR_RESET)"

validate: ## Validate YAML configuration files
	@echo "$(COLOR_BLUE)Validating configuration files...$(COLOR_RESET)"
	@if command -v yamllint >/dev/null 2>&1; then \
		yamllint $(SOURCE_DIR)/*.yaml && \
		echo "$(COLOR_GREEN)✓ YAML validation passed$(COLOR_RESET)"; \
	elif command -v python3 >/dev/null 2>&1; then \
		if python3 -c "import yaml" 2>/dev/null; then \
			python3 -c "import yaml, sys; \
				[yaml.safe_load(open('$(SOURCE_DIR)/' + f)) for f in ['config.yaml', 'policy.yaml']] \
				and print('$(COLOR_GREEN)✓ YAML syntax valid$(COLOR_RESET)')"; \
		else \
			echo "$(COLOR_YELLOW)⚠ Python yaml module not installed$(COLOR_RESET)"; \
			echo "$(COLOR_YELLOW)  Install with: pip3 install pyyaml$(COLOR_RESET)"; \
			echo "$(COLOR_YELLOW)  Skipping validation...$(COLOR_RESET)"; \
		fi \
	else \
		echo "$(COLOR_YELLOW)⚠ No YAML validator found (install yamllint or python3 with pyyaml)$(COLOR_RESET)"; \
		echo "$(COLOR_YELLOW)  Skipping validation...$(COLOR_RESET)"; \
	fi
	@if [ -f "$(CODEX_SOURCE_FILE)" ]; then \
		if command -v python3 >/dev/null 2>&1; then \
			err=$$(python3 -c "$(TOML_CHECK_PY)" "$(CODEX_SOURCE_FILE)" 2>&1); rc=$$?; \
			if [ $$rc -eq 0 ]; then \
				echo "$(COLOR_GREEN)✓ TOML syntax valid$(COLOR_RESET)"; \
			elif [ $$rc -eq 2 ]; then \
				echo "$(COLOR_YELLOW)⚠ No TOML parser found (needs Python 3.11+ or tomli)$(COLOR_RESET)"; \
				echo "$(COLOR_YELLOW)  Install with: pip3 install tomli$(COLOR_RESET)"; \
				echo "$(COLOR_YELLOW)  Skipping TOML validation...$(COLOR_RESET)"; \
			else \
				echo "$(COLOR_RED)✗ Invalid TOML in $(CODEX_SOURCE_FILE)$(COLOR_RESET)"; \
				echo "$$err" | tail -n 3; \
				exit 1; \
			fi; \
		else \
			echo "$(COLOR_YELLOW)⚠ python3 not found; skipping TOML validation$(COLOR_RESET)"; \
		fi; \
	else \
		echo "$(COLOR_YELLOW)⚠ $(CODEX_SOURCE_FILE) not found; skipping Codex config validation$(COLOR_RESET)"; \
	fi

backup: init ## Backup existing configuration files
	@echo "$(COLOR_BLUE)Backing up existing configuration...$(COLOR_RESET)"
	@if [ -f "$(CLAUDE_CONFIG_DIR)/config.yaml" ] || [ -f "$(CLAUDE_CONFIG_DIR)/policy.yaml" ] || [ -f "$(CODEX_CONFIG_DIR)/config.toml" ]; then \
		mkdir -p $(BACKUP_DIR)/$(TIMESTAMP); \
		[ -f "$(CLAUDE_CONFIG_DIR)/config.yaml" ] && \
			cp $(CLAUDE_CONFIG_DIR)/config.yaml $(BACKUP_DIR)/$(TIMESTAMP)/config.yaml && \
			echo "$(COLOR_GREEN)✓ Backed up config.yaml$(COLOR_RESET)"; \
		[ -f "$(CLAUDE_CONFIG_DIR)/policy.yaml" ] && \
			cp $(CLAUDE_CONFIG_DIR)/policy.yaml $(BACKUP_DIR)/$(TIMESTAMP)/policy.yaml && \
			echo "$(COLOR_GREEN)✓ Backed up policy.yaml$(COLOR_RESET)"; \
		[ -f "$(CODEX_CONFIG_DIR)/config.toml" ] && \
			cp $(CODEX_CONFIG_DIR)/config.toml $(BACKUP_DIR)/$(TIMESTAMP)/config.toml && \
			echo "$(COLOR_GREEN)✓ Backed up codex config.toml$(COLOR_RESET)"; \
		echo "$(COLOR_GREEN)Backup saved to: $(BACKUP_DIR)/$(TIMESTAMP)$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)No existing configuration found to backup$(COLOR_RESET)"; \
	fi

install: init backup ## Install configuration files to Claude config directory
	@echo "$(COLOR_BLUE)Installing configuration files...$(COLOR_RESET)"
	@cp $(SOURCE_DIR)/config.yaml $(CLAUDE_CONFIG_DIR)/config.yaml
	@echo "$(COLOR_GREEN)✓ Installed config.yaml$(COLOR_RESET)"
	@cp $(SOURCE_DIR)/policy.yaml $(CLAUDE_CONFIG_DIR)/policy.yaml
	@echo "$(COLOR_GREEN)✓ Installed policy.yaml$(COLOR_RESET)"
	@if [ -f "$(CODEX_SOURCE_FILE)" ]; then \
		cp $(CODEX_SOURCE_FILE) $(CODEX_CONFIG_DIR)/config.toml; \
		echo "$(COLOR_GREEN)✓ Installed codex config.toml$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)⚠ $(CODEX_SOURCE_FILE) not found; skipped Codex install$(COLOR_RESET)"; \
	fi
	@echo ""
	@echo "$(COLOR_GREEN)✓ Configuration deployed successfully!$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)Configuration location: $(CLAUDE_CONFIG_DIR)$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)Codex config location: $(CODEX_CONFIG_DIR)$(COLOR_RESET)"

install-local: init ## Install configuration files to local directory only
	@echo "$(COLOR_BLUE)Configuration already in local directory$(COLOR_RESET)"
	@echo "$(COLOR_GREEN)✓ Local setup complete$(COLOR_RESET)"

test: validate ## Test configuration syntax
	@echo "$(COLOR_BLUE)Running configuration tests...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Checking for required fields...$(COLOR_RESET)"
	@if grep -q "version:" $(SOURCE_DIR)/config.yaml; then \
		echo "$(COLOR_GREEN)✓ config.yaml has version field$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED)✗ config.yaml missing version field$(COLOR_RESET)"; \
		exit 1; \
	fi
	@if grep -q "permissions:" $(SOURCE_DIR)/policy.yaml; then \
		echo "$(COLOR_GREEN)✓ policy.yaml has permissions field$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED)✗ policy.yaml missing permissions field$(COLOR_RESET)"; \
		exit 1; \
	fi
	@echo "$(COLOR_GREEN)✓ All tests passed$(COLOR_RESET)"

diff: ## Show differences between local and installed configs
	@echo "$(COLOR_BLUE)Configuration differences:$(COLOR_RESET)"
	@echo ""
	@if [ -f "$(CLAUDE_CONFIG_DIR)/config.yaml" ]; then \
		echo "$(COLOR_YELLOW)config.yaml:$(COLOR_RESET)"; \
		diff -u $(CLAUDE_CONFIG_DIR)/config.yaml $(SOURCE_DIR)/config.yaml || true; \
	else \
		echo "$(COLOR_YELLOW)No installed config.yaml found$(COLOR_RESET)"; \
	fi
	@echo ""
	@if [ -f "$(CLAUDE_CONFIG_DIR)/policy.yaml" ]; then \
		echo "$(COLOR_YELLOW)policy.yaml:$(COLOR_RESET)"; \
		diff -u $(CLAUDE_CONFIG_DIR)/policy.yaml $(SOURCE_DIR)/policy.yaml || true; \
	else \
		echo "$(COLOR_YELLOW)No installed policy.yaml found$(COLOR_RESET)"; \
	fi
	@echo ""
	@if [ -f "$(CODEX_CONFIG_DIR)/config.toml" ] && [ -f "$(CODEX_SOURCE_FILE)" ]; then \
		echo "$(COLOR_YELLOW)codex config.toml:$(COLOR_RESET)"; \
		diff -u $(CODEX_CONFIG_DIR)/config.toml $(CODEX_SOURCE_FILE) || true; \
	elif [ ! -f "$(CODEX_SOURCE_FILE)" ]; then \
		echo "$(COLOR_YELLOW)No source Codex config found$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)No installed codex config.toml found$(COLOR_RESET)"; \
	fi

uninstall: ## Remove installed configuration files (keeps backups)
	@echo "$(COLOR_BLUE)Uninstalling configuration files...$(COLOR_RESET)"
	@if [ -f "$(CLAUDE_CONFIG_DIR)/config.yaml" ] || [ -f "$(CLAUDE_CONFIG_DIR)/policy.yaml" ] || [ -f "$(CODEX_CONFIG_DIR)/config.toml" ]; then \
		$(MAKE) backup; \
		rm -f $(CLAUDE_CONFIG_DIR)/config.yaml; \
		rm -f $(CLAUDE_CONFIG_DIR)/policy.yaml; \
		rm -f $(CODEX_CONFIG_DIR)/config.toml; \
		echo "$(COLOR_GREEN)✓ Configuration files removed$(COLOR_RESET)"; \
		echo "$(COLOR_BLUE)Backups preserved in: $(BACKUP_DIR)$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)No configuration files to uninstall$(COLOR_RESET)"; \
	fi

restore: ## Restore from the most recent backup
	@echo "$(COLOR_BLUE)Restoring from backup...$(COLOR_RESET)"
	@LATEST_BACKUP=$$(ls -t $(BACKUP_DIR) 2>/dev/null | head -1); \
	if [ -n "$$LATEST_BACKUP" ]; then \
		cp $(BACKUP_DIR)/$$LATEST_BACKUP/config.yaml $(CLAUDE_CONFIG_DIR)/config.yaml 2>/dev/null && \
			echo "$(COLOR_GREEN)✓ Restored config.yaml$(COLOR_RESET)"; \
		cp $(BACKUP_DIR)/$$LATEST_BACKUP/policy.yaml $(CLAUDE_CONFIG_DIR)/policy.yaml 2>/dev/null && \
			echo "$(COLOR_GREEN)✓ Restored policy.yaml$(COLOR_RESET)"; \
		cp $(BACKUP_DIR)/$$LATEST_BACKUP/config.toml $(CODEX_CONFIG_DIR)/config.toml 2>/dev/null && \
			echo "$(COLOR_GREEN)✓ Restored codex config.toml$(COLOR_RESET)"; \
		echo "$(COLOR_GREEN)Restored from: $(BACKUP_DIR)/$$LATEST_BACKUP$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED)✗ No backups found$(COLOR_RESET)"; \
		exit 1; \
	fi

list-backups: ## List all available backups
	@echo "$(COLOR_BLUE)Available backups:$(COLOR_RESET)"
	@if [ -d "$(BACKUP_DIR)" ]; then \
		ls -lh $(BACKUP_DIR) 2>/dev/null || echo "$(COLOR_YELLOW)No backups found$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Backup directory does not exist$(COLOR_RESET)"; \
	fi

clean: ## Clean up logs and temporary files
	@echo "$(COLOR_BLUE)Cleaning up...$(COLOR_RESET)"
	@rm -rf logs/*.log
	@echo "$(COLOR_GREEN)✓ Logs cleaned$(COLOR_RESET)"

clean-all: clean ## Clean logs and all backups (use with caution!)
	@echo "$(COLOR_RED)⚠  This will delete all backups!$(COLOR_RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		rm -rf $(BACKUP_DIR); \
		echo "$(COLOR_GREEN)✓ All backups removed$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Cancelled$(COLOR_RESET)"; \
	fi

status: ## Show current configuration status
	@echo "$(COLOR_BLUE)Configuration Status$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_YELLOW)Source files:$(COLOR_RESET)"
	@ls -lh $(SOURCE_DIR)/*.yaml
	@echo ""
	@echo "$(COLOR_YELLOW)Installed location:$(COLOR_RESET) $(CLAUDE_CONFIG_DIR)"
	@if [ -d "$(CLAUDE_CONFIG_DIR)" ]; then \
		ls -lh $(CLAUDE_CONFIG_DIR)/*.yaml 2>/dev/null || echo "  No configuration files installed"; \
	else \
		echo "  Directory does not exist"; \
	fi
	@echo ""
	@echo "$(COLOR_YELLOW)Codex location:$(COLOR_RESET) $(CODEX_CONFIG_DIR)"
	@if [ -f "$(CODEX_CONFIG_DIR)/config.toml" ]; then \
		ls -lh $(CODEX_CONFIG_DIR)/config.toml; \
	else \
		echo "  No Codex config installed"; \
	fi
	@echo ""
	@echo "$(COLOR_YELLOW)Backups:$(COLOR_RESET)"
	@if [ -d "$(BACKUP_DIR)" ]; then \
		BACKUP_COUNT=$$(ls -1 $(BACKUP_DIR) 2>/dev/null | wc -l | tr -d ' '); \
		echo "  $$BACKUP_COUNT backup(s) available"; \
	else \
		echo "  No backups"; \
	fi

check-deps: ## Check for optional dependencies
	@echo "$(COLOR_BLUE)Checking dependencies...$(COLOR_RESET)"
	@command -v yamllint >/dev/null 2>&1 && \
		echo "$(COLOR_GREEN)✓ yamllint$(COLOR_RESET)" || \
		echo "$(COLOR_YELLOW)✗ yamllint (optional, for validation)$(COLOR_RESET)"
	@command -v python3 >/dev/null 2>&1 && \
		echo "$(COLOR_GREEN)✓ python3$(COLOR_RESET)" || \
		echo "$(COLOR_YELLOW)✗ python3 (optional, for validation)$(COLOR_RESET)"
	@command -v git >/dev/null 2>&1 && \
		echo "$(COLOR_GREEN)✓ git$(COLOR_RESET)" || \
		echo "$(COLOR_YELLOW)✗ git (optional, for version control)$(COLOR_RESET)"
