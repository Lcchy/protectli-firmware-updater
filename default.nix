{pkgs ? import <nixpkgs> {}}: let
  fhsEnv = pkgs.buildFHSUserEnv {
    name = "fhs-env";
    targetPkgs = pkgs:
      with pkgs; [
        coreutils
        ncurses
        dmidecode
        mokutil

        # vendor binary deps
        pciutils
        libusb1
        libftdi1
      ];
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "protectli-flashbios";
    version = "1.1.49";

    src = ./.;

    nativeBuildInputs = [
      fhsEnv
      pkgs.makeWrapper
      pkgs.python3
    ];

    dontBuild = true;

    installPhase = ''
    # Set up Python files
    mkdir -p $out/lib/python/
    cp -r flashli $out/lib/python/

    # include vendor binaries
    cp -r vendor $out

    # Create the main script that will run in FHS
    mkdir -p $out/libexec
    cp flashbios $out/libexec/flashbios-unwrapped
    chmod +x $out/libexec/flashbios-unwrapped

    # Create a wrapper script that runs Python
    mkdir -p $out/bin
    cat > $out/bin/flashbios-wrapped <<EOF
    #!${pkgs.bash}/bin/bash
    exec python3 $out/libexec/flashbios-unwrapped "\$@"
    EOF
    chmod +x $out/bin/flashbios-wrapped

    # Create the wrapper script that uses FHS
    mkdir -p $out/bin
    makeWrapper${fhsEnv}/bin/fhs-env $out/bin/flashbios \
                        --add-flags "$out/bin/sdf-wrapped" \
                        --prefix PYTHONPATH : "$out/lib/python"
    '';
  }
