{ pkgs }: {
	deps = [
		pkgs.nettools
  pkgs.killall
  pkgs.erlang
		pkgs.rebar3
    pkgs.erlang-ls
    pkgs.unixtools.netstat
	];
}