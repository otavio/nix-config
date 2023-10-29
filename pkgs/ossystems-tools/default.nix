{ chickenPackages_4
, makeWrapper
}:

let
  comparse = chickenPackages_4.eggDerivation {
    name = "comparse";

    src = chickenPackages_4.fetchegg {
      name = "comparse";
      version = "3";
      sha256 = "fLPryTGAypPTCNQpBbA9PCP9wIJZuajpyflxL9ZP2jw=";
    };

    buildInputs = [
      lazy-seq
      matchable
      trie
    ];
  };

  input-parse = chickenPackages_4.eggDerivation {
    name = "input-parse";

    src = chickenPackages_4.fetchegg {
      name = "input-parse";
      version = "1.1";
      sha256 = "r4OghYuWXK5bbcS7QwI2wxc/OVoYOhZvVDgWeEDXIP0=";
    };

    buildInputs = [

    ];
  };

  lazy-seq = chickenPackages_4.eggDerivation {
    name = "lazy-seq";

    src = chickenPackages_4.fetchegg {
      name = "lazy-seq";
      version = "2";
      sha256 = "Hu4SKlmhqTywe3wY5wZnhBJiq726OKAixTdO3XOlFH0=";
    };

    buildInputs = [

    ];
  };

  make = chickenPackages_4.eggDerivation {
    name = "make";

    src = chickenPackages_4.fetchegg {
      name = "make";
      version = "1.8";
      sha256 = "MG0P4og3mNI7KcW2ptXSTs7A/WzxtiB2Q13Eq7zU3fA=";
    };

    buildInputs = [

    ];
  };

  matchable = chickenPackages_4.eggDerivation {
    name = "matchable";

    src = chickenPackages_4.fetchegg {
      name = "matchable";
      version = "3.7";
      sha256 = "0AeihPgIDHladntGd5D8iTeDko30fRiSBRY6QtbNie0=";
    };

    buildInputs = [

    ];
  };


  medea = chickenPackages_4.eggDerivation {
    name = "medea";

    src = chickenPackages_4.fetchegg {
      name = "medea";
      version = "4";
      sha256 = "sha256-Q6zbwBDE0xW/+9H50qCnKovSe79dl0TPMbxsRcn/fF0=";
    };

    buildInputs = [
      comparse
    ];
  };

  regex = chickenPackages_4.eggDerivation {
    name = "regex";

    src = chickenPackages_4.fetchegg {
      name = "regex";
      version = "1.0";
      sha256 = "sha256-Ls5an5zzNT40W1lhn00M/pZ9BZgSfU0bK9AstfuBK/0=";
    };

    buildInputs = [

    ];
  };

  simple-sha1 = chickenPackages_4.eggDerivation {
    name = "simple-sha1";

    src = chickenPackages_4.fetchegg {
      name = "simple-sha1";
      version = "0.4";
      sha256 = "sha256-IOh/zvDYK+ebEZhojH6t+7hq3YYHViP6goOJEwnqLHE=";
    };

    buildInputs = [

    ];
  };

  ssax = chickenPackages_4.eggDerivation {
    name = "ssax";

    src = chickenPackages_4.fetchegg {
      name = "ssax";
      version = "5.0.7";
      sha256 = "m0ohPpd45xlERb2Vs8CVgPo2p8N0CksOrqNYa+7x+ss=";
    };

    buildInputs = [
      input-parse
    ];
  };

  sxml-transforms = chickenPackages_4.eggDerivation {
    name = "sxml-transforms";

    src = chickenPackages_4.fetchegg {
      name = "sxml-transforms";
      version = "1.4.1";
      sha256 = "QpnDmPeCFzroGYbaHar8yqRZdgFhTiUqryWGagMc9cU=";
    };

    buildInputs = [

    ];
  };

  sxpath = chickenPackages_4.eggDerivation {
    name = "sxpath";

    src = chickenPackages_4.fetchegg {
      name = "sxpath";
      version = "0.2.1";
      sha256 = "pEWW3omyepum/3zjFVSEPc7/WxXaMneyxKy4rgIWIGk=";
    };

    buildInputs = [

    ];
  };

  trie = chickenPackages_4.eggDerivation {
    name = "trie";

    src = chickenPackages_4.fetchegg {
      name = "trie";
      version = "2";
      sha256 = "xxL+CoO1ggOcw2vjQYGCed+rALASrN2/ZVPCgB7zkK0=";
    };

    buildInputs = [

    ];
  };

in

chickenPackages_4.eggDerivation {
  name = "ossystems-tools";

  src = builtins.fetchGit {
    url = "git@github.com:OSSystems/ossystems-tools.git";
    rev = "6bc183bff7af116d82d4221df98cdc80fb5a3c1c";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = with chickenPackages_4.chickenEggs; [
    http-client
    make
    medea
    matchable
    regex
    simple-sha1
    ssax
    sxml-transforms
    sxpath
    uri-common
  ];
}
