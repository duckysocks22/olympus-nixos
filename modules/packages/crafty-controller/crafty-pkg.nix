{
  lib,
  pkgs,
}:
let
  # Crafty pins peewee==3.13 in requirements.txt. peewee 3.17+ changed SQLite
  # DROP COLUMN behaviour in migrations, which breaks Crafty's migration runner.
  #
  # peewee 3.13.0's Cython extensions reference the Python 2 `long` type and
  # use Cython 0.x exception semantics — neither compile on Python 3.13 + Cython
  # 3.x. Removing Cython from nativeBuildInputs causes setup.py to fall back to
  # pure-Python mode, which is sufficient for Crafty's use case.
  peewee-313 = pkgs.python3Packages.peewee.overridePythonAttrs (_old: rec {
    version = "3.13.0";
    src = pkgs.fetchPypi {
      pname = "peewee";
      inherit version;
      hash = "sha256-1tVLCxK4VYzdU9aqa1uqQOg3jSjH96I7IL4QQZllbt0=";
    };
    # Stub out the Cython imports so setup.py produces a pure-Python build
    # regardless of what is on PYTHONPATH in the build environment.
    # cythonize() returns [] so ext_modules ends up empty; build_ext is
    # set to None which is harmless when there are no extensions to compile.
    postPatch = ''
      sed -i \
        -e '1s/^/def cythonize(*a, **k): return []\n/' \
        -e 's/\( *\)from Cython\.Build import cythonize/\1pass/' \
        -e 's/from Cython\.Distutils import build_ext/from setuptools.command.build_ext import build_ext/' \
        setup.py
    '';
  });
in
with pkgs.python3Packages;

buildPythonApplication (finalAttrs: {
  pname = "crafty-controller";
  version = "4.10.4";

  src = pkgs.fetchFromGitLab {
    owner = "crafty-controller";
    repo = "crafty-4";
    rev = "v${finalAttrs.version}";
    hash = "sha256-6nbOkpl847wbvB0/9y7qvgbzy9EhgOdHBt6DTgmyShk=";
  };

  format = "other";

  doCheck = false;

  propagatedBuildInputs = [
    aiofiles
    anyio
    apscheduler
    argon2-cffi
    cached-property
    distro
    colorama
    croniter
    cryptography
    httpx
    jinja2
    jsonschema
    libgravatar
    nh3
    orjson
    packaging
    peewee-313
    pillow
    prometheus-client
    psutil
    pyjwt
    pyotp
    webauthn
    pyyaml
    requests
    termcolor
    tornado
    tzlocal
    pyopenssl
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/crafty-controller
    cp -r . $out/share/crafty-controller

    runHook postInstall
  '';

  # Instead of symlinking app/ into $CRAFTY_HOME (which leaves it pointing at the
  # read-only store), we write a launcher script that copies the full source tree
  # into a writable $CRAFTY_HOME on first run.  On upgrades (detected via the
  # .nix-store-path marker) only the code — app/ and main.py — is refreshed so
  # that user data (servers/, config/, logs/, local/) is never clobbered.
  postFixup = ''
    cat > $out/bin/crafty-controller << EOF
#!/bin/sh
CRAFTY_HOME="\''${CRAFTY_HOME:-\$HOME/.local/share/crafty-controller}"
VERSION_MARKER="\$CRAFTY_HOME/.nix-store-path"

if [ ! -d "\$CRAFTY_HOME" ]; then
  echo "Installing crafty-controller to \$CRAFTY_HOME..."
  mkdir -p "\$CRAFTY_HOME"
  cp -r $out/share/crafty-controller/. "\$CRAFTY_HOME/"
  chmod -R u+w "\$CRAFTY_HOME"
  echo "$out" > "\$VERSION_MARKER"
elif [ ! -f "\$VERSION_MARKER" ] || [ "\$(cat "\$VERSION_MARKER")" != "$out" ]; then
  echo "Updating crafty-controller in \$CRAFTY_HOME..."
  cp -r $out/share/crafty-controller/app "\$CRAFTY_HOME/app"
  cp $out/share/crafty-controller/main.py "\$CRAFTY_HOME/main.py"
  chmod -R u+w "\$CRAFTY_HOME/app" "\$CRAFTY_HOME/main.py"
  echo "$out" > "\$VERSION_MARKER"
fi

mkdir -p "\$CRAFTY_HOME/logs" "\$CRAFTY_HOME/local" "\$CRAFTY_HOME/servers" "\$CRAFTY_HOME/config"
cd "\$CRAFTY_HOME"
PYTHONPATH="${makePythonPath finalAttrs.propagatedBuildInputs}:\$CRAFTY_HOME" PATH="${pkgs.jdk25}/bin:\$PATH" LD_LIBRARY_PATH="${pkgs.libudev-zero}/lib:\$LD_LIBRARY_PATH" exec ${python}/bin/python "\$CRAFTY_HOME/main.py" "\$@"
EOF
    chmod +x $out/bin/crafty-controller
  '';

  meta = {
    description = "Minecraft server wrapper/controller built in python";
    homepage = "https://docs.craftycontrol.com";
    downloadPage = "https://gitlab.com/crafty-controller/crafty-4";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ duckysocks22 ];
    mainProgram = "crafty-controller";
  };
})
