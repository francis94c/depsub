# depsub

[![pub version](https://img.shields.io/pub/v/depsub.svg)](https://pub.dev/packages/depsub) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

depsub is a small, focused Dart command-line tool for managing and applying deterministic dependency overrides in local Dart and Flutter projects. It helps maintainers and engineers apply, preview, and revert dependency overrides across workspaces and packages in a reproducible, auditable way.

Why depsub?

- Small and focused: solves the common pain of managing local or patched dependency overrides.
- Deterministic: provides dry-run and diff modes so you can inspect changes before applying them.
- CI-friendly: non-interactive flags and predictable output make it suitable for automation.
- Test-covered: includes unit tests and clear error messages to help maintain confidence when used in important workflows.

Key Features

- Apply overrides from a single YAML manifest (defaults to `local-deps.yaml`).
- Revert previously-applied overrides.
- Show diffs and dry-run previews before changing files.
- Operate on a single package or an entire workspace.
- Designed for use in CI pipelines and developer workflows.

Install

- From pub.dev (recommended):

```bash
dart pub global activate depsub
```

- From source (for contributors):

```bash
git clone https://github.com/your-username/depsub.git
cd depsub
dart pub get
dart run bin/depsub.dart --help
```

Quick Start

1. Create a `local-deps.yaml` in your repository. Example:

```yaml
overrides:
	some_package:
		path: ../local/some_package
	patched_dep:
		hosted:
			name: patched_dep
			url: https://example.com/patched_dep.tar.gz
```

2. Preview what will change:

```bash
depsub apply --manifest local-deps.yaml --dry-run
```

3. Apply overrides:

```bash
depsub apply --manifest local-deps.yaml
```

4. Revert overrides:

```bash
depsub revert --manifest local-deps.yaml
```

Commands & Flags

- `apply` — Apply overrides described in the manifest.
- `revert` — Revert previously applied overrides.
- `diff` — Show what would change.
- `--manifest` (`-m`) — Path to the manifest file (defaults to `local-deps.yaml`).
- `--package` (`-p`) — Path to a single package to operate on.
- `--dry-run` — Show changes without writing files.
- `--yes` — Skip confirmation prompts (useful in CI).

Configuration

- Manifest name: `local-deps.yaml` by default; pass another file with `--manifest`.
- See the example `local-deps.yaml` in this repo for supported override forms.

Testing

Run unit tests included under `test/`:

```bash
dart test
```

Contributing

- Contributions and bug reports are welcome. Open issues and PRs on the project's GitHub.
- Please run `dart format` and unit tests before submitting changes.

Roadmap

- Add support for git-based overrides and custom registries.
- Interactive mode for exploratory development.
- Official GitHub Actions for easy CI integration.

Security & Privacy

- `depsub` modifies only local project files. It does not contact external services unless you use hosted or URL-based overrides.
- Always review manifests and dry-run output before applying in production.

Author & Maintenance

- Maintained by You (replace with your name). I build developer tools, automation, and workflows that prioritize reliability and developer experience.

LinkedIn-ready summary you can reuse:

"Author of `depsub`, a Dart CLI that makes dependency overrides deterministic and auditable for Dart/Flutter projects. Skilled in developer tooling, CI automation, and reproducible builds."

License

- MIT — see the [LICENSE](LICENSE) file.

Acknowledgements

- Inspired by the challenges of local package development, reproducible CI builds, and maintainable open-source tooling.

Contact

- Report issues or request features via the repository issue tracker.
- For quick questions, mention the repo or reach out on LinkedIn.

---

If you'd like, I can also generate a concise LinkedIn post announcing the package and produce a polished `pubspec.yaml` entry for publishing—tell me which you'd prefer next.
A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.
