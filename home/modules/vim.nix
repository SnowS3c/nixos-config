{ pkgs, ... }:

let
  ansible-snippets = pkgs.vimUtils.buildVimPlugin {
    name = "ansible-snippets";

    src = pkgs.fetchFromGitHub {
      owner = "phenomenes";
      repo = "ansible-snippets";
      rev = "master";
      hash = "sha256-5ZybwrHBKxZK7FIK4aaqzK9oaiIj/0wYkrUU6lXmdhc=";
    };
  };

in

{
  programs.vim = {

    enable = true;

    defaultEditor = true;

    plugins = with pkgs.vimPlugins; [
      nerdtree
      fzf-vim
      vim-gitgutter
      vim-fugitive
      vim-floaterm
      ultisnips
      vim-snippets
      ansible-snippets
      gruvbox
    ];

      extraConfig = builtins.readFile ./vimrc;
  };
}
