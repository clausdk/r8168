# Repository Guidelines

## Project Structure & Module Organization
- Kernel module sources live in `src/` (C driver files, headers, kernel-aware `Makefile` variants). Top-level `Makefile` delegates to `src/` and selects the 2.4-compatible makefile when needed.
- Installation helpers: `autorun.sh` builds/installs for the running kernel; `dkms-install.sh` + `dkms.conf` support DKMS builds; docs sit at the root.
- Built artifacts stay in `src/` (e.g., `r8168.ko`) unless install targets copy them into the kernel tree.

## Build, Test, and Development Commands
- `make` (root): cleans, builds, and installs the module for the running kernel by calling `src/Makefile`.
- `make modules` / `make clean` (root): build or clean only.
- `make -C src/ modules` or `modules_install`: build/install against the detected kernel headers (`KERNELDIR` overridable).
- `sudo ./dkms-install.sh`: install via DKMS; auto-rebuilds on kernel updates and blacklists `r8169`.
- Load & verify locally: `sudo insmod ./src/r8168.ko` (or `modprobe r8168` after install), then `lsmod | grep r8168` and `modinfo r8168`.

## Coding Style & Naming Conventions
- Follow Linux kernel coding style: tabs for indentation, 80–100 character lines, K&R braces, `snake_case` for symbols, and `r8168_*` prefixes for shared helpers.
- Keep configuration flags in `src/Makefile` (`ENABLE_FIBER_SUPPORT`, `ENABLE_RSS_SUPPORT`, etc.) grouped and documented when adding new build-time toggles.
- Prefer minimal dependencies and kernel-provided helpers; mirror existing patterns before introducing new abstractions.

## Testing Guidelines
- Primary test is a clean kernel build: `make clean && make modules` (or `make -C src/ modules`).
- For DKMS flows, run `sudo dkms build -m r8168 -v <version>` followed by `sudo dkms install ...`; confirm with `dkms status`.
- Runtime smoke checks: load the module, verify link up via `ip link`/`ethtool`, and review `dmesg` for warnings. No unit test suite exists; add self-tests only with rationale.

## Commit & Pull Request Guidelines
- Commit messages: short imperative summaries with context, e.g., `Add DKMS support for kernel 6.10+`; include subsystem tags if helpful (`dkms:`, `aspm:`).
- PRs should describe the motivation, kernel versions tested, commands run (`make`, DKMS build, load checks), and configuration flags touched. Link issues/bugs and include `dmesg` snippets when changing runtime behavior.
- Keep patches minimal; split driver logic, build-system changes, and docs into separate commits when practical.

## Security & Configuration Tips
- Blacklist `r8169` when deploying this driver (`/etc/modprobe.d/blacklist-r8169.conf`) to avoid module conflicts.
- When toggling power or wake features (e.g., `ENABLE_EEE`, `ENABLE_S5WOL`), note their defaults in commit messages and docs to aid downstream integrators.
