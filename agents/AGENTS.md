# Personal preferences — James Laird-Smith (jls)

These are instructions for AI coding agents working in my repositories. For full
configuration details, see my dotfiles repo at `~/projects/dotfiles/`.

## English

Use British English over American English.

## Nix

Try to use Nix for everything. If there is ever a choice between the Nix way of
doing something and a non-Nix way, always prefer the Nix-way, while providing a
message to the user to that effect. This should also extend to Nix shell
configurations. If there is a choice between using a system-wide tool and adding
a new tool to the Nix-shell, always prefer adding a new tool to the Nix shell.
If the change is significant enough, prompt the user before making the change.

Nix is also used for my system configuration. Details can be found in the "nix/"
folder of my dotfiles repo. I use nix-darwin and Mome Manager. When inside a
project with a Nix shell, prefer making changes to the Nix shell envrionment
rather than in the dotfiles repository. Some exceptions to this are given below.
When a change is not possible inside the Nix shell (for example, a project needs
a homebrew package) then suggest the change for the dotfiles repo and ask the
user for confirmation before proceeding.

Here is a list of the things which should be configured in the dotfiles
repository rather than a local Nix shell:

- VS Code
- Worktrunk
- Fish

Nix files should be formatted with `nixfmt` and the Nix language server of
choice is `nixd`.

## Text editing preferences

- Format on save is enabled.
- Word wrap at column 80; ruler at 80.
- Minimap disabled.
- Markdown formatted with Prettier (prose wrap always, print width 80).
- Caps Lock is remapped to Escape system-wide.

## System

My usual system is macOS on Apple Silicon (aarch64-darwin). Although I do
sometimes work on other systems and would like to maintain as much portability
as possible, especially inside Nix shell envrionments.

Default shell is **Fish**. Bash and Zsh are also configured with equivalent
aliases and functions.

Terminal emulator is usually **Ghostty**.

Primary editor is usually **VS Code** with extensions.

## Git workflow

I use both worktree and non-worktree Git workflows. When using worktrees, I use
the Worktrunk `wt` tool with a custom pattern for the folders. When Worktrunk is
in use, the repo will typically be a bare clone and branches are checked out as
worktrees in sibling directories (pattern: `../<branch-name>/`). My shell config
wraps `wt remove` to always pass `--no-delete-branch`. See
`~/projects/dotfiles/worktrunk/config.toml` and the shell configs for details.

Other things:

- Common git aliases: `gs` (status), `gcl` (clone --recurse-submodules), `gch`
  (checkout), `gc` (commit), `gd` (diff), `ga` (add).
- Submodule recursion is enabled globally.

## LLM agent skills

I keep project-specific LLM agent skills in ".agents/skills". I also keep a
separate store of LLM agent skills in a Git repository. On GitHub this is
"jameslairdsmith/agent-skills" and locally I clone it into
"~/projects/agent-skills".

Both my ".agents/skills" folders and my GitHub repository follow a flat
structure with the standard agent skills layout:

```
skill-name/
├── SKILL.md      # REQUIRED: Metadata and step-by-step instructions
...
```

Whenever adding a new skill to a project, prompt me as to whether I would also
like to add it to my central repo. If I approve, also copy the skill into
"~/projects/agent-skills". If the skill is being copied from elsewhere, make
sure to include a refence and link to its origional location.

When deciding on the name of a new skill, be mindful of the flat nature of the
repo. Use kebab case and prefixes to try separate the different kinds of tool
use eg. r-ggplot2. Make sure they follow this convention, even if they are
differently named where they currently are.

## Other languages & tools

- **Python** — present but lightweight usage.
- **Elm** — extensions installed in VS Code.
- **Typst** — tinymist extension in VS Code.
- **Plover** — I use stenography software (Plover) with custom plugins.
