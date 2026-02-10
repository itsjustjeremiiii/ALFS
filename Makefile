.PHONY: menuconfig config clean help

menuconfig:
	@./tools/kconfig/mconf Config.in

config: menuconfig

clean:
	@bash -c 'source tools/colors.conf && rm -f .config .config.old && echo "$$PASS Configuration files cleaned"'

help:
	@bash -c 'source tools/colors.conf && head "Setup Config"'
	@echo ""
	@bash -c 'source tools/colors.conf && echo "$${BOLD}Available targets:$${RESET}"'
	@bash -c 'source tools/colors.conf && text "  make menuconfig  - Configure"'
	@bash -c 'source tools/colors.conf && text "  make config      - Menuconfig"'
	@bash -c 'source tools/colors.conf && text "  make clean       - Discard Config"'
	@bash -c 'source tools/colors.conf && text "  make help        - Help"'
