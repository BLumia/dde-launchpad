{ stdenv
, lib
, fetchFromGitHub
, nix-filter
, cmake
, qttools
, pkg-config
, wrapQtAppsHook
, dtkdeclarative
, qtbase
, qtsvg
, appstream-qt ? null
}:

stdenv.mkDerivation rec {
  pname = "dde-launchpad";
  version = "0.2.1";

  src = nix-filter.filter {
    root = ./..;

    exclude = [
      ".git"
      "debian"
      "LICENSES"
      "README.md"
      "README.zh_CN.md"
      (nix-filter.matchExt "nix")
    ];
  };

  nativeBuildInputs = [
    cmake
    qttools
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    dtkdeclarative
    qtbase
    qtsvg
    appstream-qt
  ];

  cmakeFlags = [
    "-DSYSTEMD_USER_UNIT_DIR=${placeholder "out"}/lib/systemd/user"
    "-DPREFER_QT_5=OFF"
  ];

  meta = with lib; {
    description = "The 'launcher' or 'start menu' component for DDE";
    homepage = "https://github.com/linuxdeepin/dde-launchpad";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = teams.deepin.members;
  };
}
