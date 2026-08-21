{ pkgs, ... }:

{
    home.packages = with pkgs; [
        git
        wget
        fzf
        ripgrep
        fd
        (python3.withPackages (ps: with ps; [
          pygobject3
        ]))
        tree
    ];
}
