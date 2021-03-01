%% An interactive program to model toggle flipping. %%

%% signals
signal : type.
%listen signal STDIN.

state : type.
on : state.
off : state.

indicator : state -> type.
% toggling consumes a signal
toggle : signal * indicator on -o {indicator off}.
toggle' : signal * indicator off -o {indicator on}.

%reply (indicator X) STDOUT.
