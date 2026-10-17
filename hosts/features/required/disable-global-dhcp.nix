{
  # The global useDHCP flag is deprecated and takes over every interface, so
  # keep it off; NetworkManager or per-interface settings drive networking.
  networking.useDHCP = false;
}
