:- module(autodoc_aux, [], [assertions, regtypes, basicmodes, fsyntax]).

:- doc(title, "Auxiliary Definitions").
:- doc(author, "Manuel Hermenegildo").
:- doc(author, "Jose F. Morales").

:- use_module(library(messages)).
:- use_module(library(system), [file_exists/1]).

:- use_module(lpdoc(autodoc_settings)).

% ---------------------------------------------------------------------------

:- export(all_vars/1).
% All elements of the list are variables
all_vars([]).
all_vars([H|T]) :- var(H), all_vars(T).

% ---------------------------------------------------------------------------

% TODO: replace by a predicate that opens a file, and closes it if
%       fails? call_cleanup?

:- export(read_file/2).
read_file(File, Content) :-
	file_exists(File),
	!,
	open(File, read, IS),
	read_stream(IS, Content),
	close(IS).
read_file(File, []) :-
	error_message("file ~w not found", [File]).

read_stream(IS, Content) :-
	get_code(IS, N),
	( N = -1 ->
	    Content = []
	; Content = [N|Rest],
	  read_stream(IS, Rest)
	).

% ---------------------------------------------------------------------------

:- export(ascii_blank_lines/2).
ascii_blank_lines(0,"") :- !.
ascii_blank_lines(N,[0'\n | R]) :-
	N1 is N-1,
	ascii_blank_lines(N1,R).

% ---------------------------------------------------------------------------

:- use_module(library(logged_process), [logged_process_call/3]).

% TODO: logs may also be useful when status is 0
% Options for logging external commands (controlled by verbosity options)
logopts(LogOpts, A) :-
	( autodoc_option('-v') ->
	    % In verbose mode, always show logs
	    A = [show_logs(always)|LogOpts]
	; % In non-verbose, just note where logs are stored on error
	  % (change to 'on_error' to show full logs)
	  A = [show_logs(note_on_error)|LogOpts]
	).

:- export(autodoc_process_call/3).
autodoc_process_call(Cmd, Args, Opts) :-
	logged_process_call(Cmd, Args, ~logopts(Opts)).

% ---------------------------------------------------------------------------

:- use_module(lpdoc(autodoc_filesystem), [get_cache_dir0/2]).
:- use_module(library(pathnames), [path_concat/3]).

% LogBase for the given command execution RunId (relative to get_cache_dir0/2)
% (RunId is just a name to identify the command run)
% TODO: Backend should not be needed
:- export(cmd_logbase/3).
cmd_logbase(Backend, RunId, LogBase) :-
	get_cache_dir0(Backend, CacheDir),
	path_concat(CacheDir, RunId, LogBase).

% ---------------------------------------------------------------------------

:- use_module(library(format), [format/2, format_control/1]).

:- export(verbose_message/1).
:- export(verbose_message/2).

:- pred verbose_message(Text, ArgList) : format_control * list
# "The text provided in @var{Text} is printed as a message, using the
   arguments in @var{ArgList}, if @tt{autodoc_option('-v')} is
   defined. Otherwise nothing is printed.".

verbose_message(Text) :-
	verbose_message(Text, []).

verbose_message(Mess, Args) :-
	( autodoc_option('-v') ->
	    format(Mess, Args), nl
	;
	    true
	).

