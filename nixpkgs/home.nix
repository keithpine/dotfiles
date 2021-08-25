{ config, pkgs, ... }:

let
  gpg_signing_key = "3D3F5644C6151C17";
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # We are on a non-NixOS install
  targets.genericLinux.enable = true;

  # relocate bash config files
  home.file.".profile".target = ".nix-bash/profile";
  home.file.".bashrc".target = ".nix-bash/bashrc";
  home.file.".bash_profile" = {
    target = ".nix-bash/bash_profile";
    # override the bash module's definition of .bash_profile
    source = pkgs.lib.mkForce (
      pkgs.writeShellScript "bash_profile" ''
        # include .profile if it exists
        [[ -f ~/${config.home.file.".profile".target} ]] && . ~/${config.home.file.".profile".target}
        # include .bashrc if it exists
        [[ -f ~/${config.home.file.".bashrc".target} ]] && . ~/${config.home.file.".bashrc".target}
      ''
    );
  };

  xdg.configFile."nvim/parser/bash.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-bash}/parser";
  xdg.configFile."nvim/parser/c.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-c}/parser";
  xdg.configFile."nvim/parser/cpp.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-cpp}/parser";
  xdg.configFile."nvim/parser/json.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-json}/parser";
  xdg.configFile."nvim/parser/nix.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-nix}/parser";
  xdg.configFile."nvim/parser/python.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-python}/parser";
  xdg.configFile."nvim/parser/toml.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-toml}/parser";
  xdg.configFile."nvim/parser/yaml.so".source = "${pkgs.tree-sitter.builtGrammars.tree-sitter-yaml}/parser";

  home.sessionVariables = {
    EDITOR = "nvim";
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    PATH = "$HOME/.local/bin:$HOME/bin:$PATH";
    VISUAL = "nvim";
  };

  home.packages = with pkgs; [
    fd
    git-extras
    lnav
    ripgrep
    tig
  ]; 

  programs =  {
    bash = {
      enable = true;
      profileExtra = ''
        eval $(keychain --quiet --agents ssh,gpg --eval id_rsa ${gpg_signing_key})
      '';
    };

    bat.enable = true;
    bat.config.theme = "Dracula";

    git = {
      enable = true;
      aliases = {
        br = "branch --verbose";
        co = "checkout";
        ds = "diff --staged";
        st = "status --short --branch";
        amend = "commit --amend --reuse-message=HEAD";
        gr = "grep --break --heading";
      };
      delta.enable = true;
      ignores = ["tags"]; 
      userName = "Keith Pine";
      userEmail = "keith.pine@seagate.com";
      extraConfig =  {
        fetch.prune = true;
        grep.lineNumber = true;
        grep.extendRegexp = true;
        init.defaultBranch = "main";
        pull.rebase = true;
      };
      signing = {
        gpgPath = "/usr/bin/gpg";
        key = "${gpg_signing_key}";
        signByDefault = true;
      };
    };

    fzf.enable = true;
    lsd.enable = true;
    lsd.enableAliases = true;
    pazi.enable = true;

    starship = {
      enable = true;
      settings = {
        nodejs.disabled = true;
        package.disabled = true;
        time = {
          disabled = false;
          style = "bold red";
          time_format = "%y.%m.%d %r";
        };
      };
    };

    tmux = {
      enable = true;
      baseIndex = 1;
      escapeTime = 50;
      historyLimit = 100000;
      terminal = "screen-256color";
      keyMode = "vi";
      sensibleOnTop = false;
      extraConfig = ''
        set-option -sa terminal-overrides ',xterm-256color:RGB'
        set-option -g focus-events on
      '';
    };

    neovim = {
      enable = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraConfig = ''
        lua <<EOF
        local set = vim.opt
        local g = vim.g
        local nvim_lsp = require('lspconfig')

        vim.cmd [[
          syntax enable
          colorscheme dracula

          " dracula theme doesn't load properly as a nix package, so we need to manually activate it
          augroup dracula
            au!
            au VimEnter * colorscheme dracula
          augroup END

          " fzf
          nnoremap <silent> <C-p> :GFiles<CR>
          nnoremap <silent> <C-b> :Buffers<CR>
        ]]

        set.cursorline = true
        set.gdefault = true
        set.hidden = true
        set.ignorecase = true
        set.joinspaces = false
        set.scrolloff = 10
        set.shiftround = true
        set.smartcase = true
        set.splitbelow = true
        set.splitright = true
        set.swapfile = false
        set.termguicolors = true
        set.wildmode = "list:longest"
        set.wrap = false
        set.wrapscan = false

        g.mapleader = ","

        require 'nvim-treesitter.configs'.setup {
          ensure_installed = {
            "bash",
            "c",
            "cpp",
            "json",
            "nix",
            "python",
            "toml",
            "yaml",
          },
          highlight = {enable = true},
        }
        set.foldmethod = "expr"
        set.foldexpr = "nvim_treesitter#foldexpr()"

        nvim_lsp.rnix.setup{}
        nvim_lsp.pyright.setup{}
        nvim_lsp.yamlls.setup{}

        EOF
      '';

      plugins = with pkgs.vimPlugins; [
        a-vim
        dracula-vim
        fzf-vim
        nvim-compe
        nvim-lspconfig
        nvim-treesitter
        tcomment_vim
        vim-commentary
        vim-eunuch
        vim-fugitive
        vim-markdown
        vim-nix
        vim-repeat
        vim-sensible
        vim-surround
        vim-toml
        vim-unimpaired
      ];
      extraPackages = with pkgs; [
        pyright
        rnix-lsp
        yaml-language-server
      ];
    };
  };

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "21.05";
}
