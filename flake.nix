{
  description = "Parallel workspaces with bare git worktrees and tmux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      version = let
        m = builtins.match "readonly VERSION=\"([^\"]+)\"" (
          builtins.head (
            builtins.filter (line: builtins.isString line && builtins.match "readonly VERSION=.*" line != null) (
              builtins.split "\n" (builtins.readFile ./zproj)
            )
          )
        );
      in
        if m == null then "0.0.0" else builtins.head m;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "zproj";
            inherit version;
            src = self;

            dontBuild = true;
            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              runHook preInstall
              install -Dm755 zproj "$out/bin/zproj"
              wrapProgram "$out/bin/zproj" \
                --prefix PATH : ${pkgs.lib.makeBinPath [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.git
                  pkgs.tmux
                  pkgs.gnused
                  pkgs.gawk
                  pkgs.gnugrep
                  pkgs.findutils
                  pkgs.diffutils
                  pkgs.procps
                  pkgs.util-linux
                ]}
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Parallel workspaces with bare git worktrees and tmux";
              homepage = "https://github.com/khajavi/zproj";
              license = licenses.mit;
              mainProgram = "zproj";
              platforms = [ "x86_64-linux" "aarch64-linux" ];
            };
          };
        }
      );
    };
}