{ outputs, inputs }:
{
  # Adds my custom packages
  additions = final: prev: import ../pkgs { pkgs = final; };
}
