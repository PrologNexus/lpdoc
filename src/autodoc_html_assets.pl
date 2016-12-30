:- module(_, [], [assertions, fsyntax]).

:- doc(title, "Assets for the HTML Backend").
:- doc(author, "Jose F. Morales").

:- doc(module, "Predicates to manage asset data (file hierarchies for
   images, CSS files, JavaScript code, etc.) to be used in the output
   of the HTML backend.").

:- use_module(library(pathnames), [path_basename/2]).
:- use_module(library(messages), [note_message/1, error_message/2]).
:- use_module(library(system), [file_exists/1, copy_file/3]).

:- use_module(lpdoc(autodoc_settings)).
:- use_module(lpdoc(autodoc_filesystem)).

% ---------------------------------------------------------------------------
:- doc(section, "CSS files").

:- use_module(library(bundle/bundle_paths), [bundle_path/3]).

:- export(prepare_auxfiles_html/2).
prepare_auxfiles_html(Backend, Opts) :-
	( all_setting_values(html_asset, AssetDirs) ->
	    prepare_assets(AssetDirs)
	; true
	),
	( member(no_math, Opts) ->
	    true
	; prepare_mathjax
	),
	% Copy CSS files
	( % (failure-driven loop)
	  css_file(CSSPath),
	    path_basename(CSSPath, CSSBase),
	    absfile_for_aux(CSSBase, Backend, OutCSS),
	    copy_file(CSSPath, OutCSS, [overwrite]),
	    fail
	; true
	).

:- export(css_file/1).
% Enumerate CSS files (absolute path) for the current settings
css_file(Path) :-
	F = 'lpdoc.css',
	setting_value(lpdoclib, Dir),
	path_concat(Dir, F, Path).
css_file(Path) :-
	\+ setting_value(syntax_highlight, no),
	F = 'ciao-htmlfontify.css',
	bundle_path(core, 'library/syntax_highlight/css', Dir),
	path_concat(Dir, F, Path).

% ---------------------------------------------------------------------------
:- doc(section, "Custom HTML assets").
% (images, css, etc.)

prepare_assets(Dirs) :-
	( % (failure-driven loop)
	  member(D, Dirs),
	    prepare_asset(D),
	    fail
	; true
	).

:- use_module(library(source_tree), [copy_file_tree/5]).

%:- export(prepare_asset/1).
:- pred prepare_asset(+SrcDir)
   # "Copy contents (recursively) of @var{SrcDir} into @tt{htmldir}.".
% TODO: Avoid copy if not necessary
prepare_asset(SrcDir) :-
	HtmlDir = ~setting_value_or_default(htmldir),
	Owner = ~setting_value_or_default(owner),
	Group = ~setting_value_or_default(group),
	Perms = ~setting_value_or_default(perms),
	%
	( file_exists(SrcDir) ->
	    true
	; error_message("No asset found at '~w'", [SrcDir]),
	  fail
	),
	copy_file_tree(installable_precomp(full),
	               SrcDir, HtmlDir, Perms, owner(Owner, Group)).

% ---------------------------------------------------------------------------
:- doc(section, "Math engine (MathJax)").
% TODO: Add support for much faster KaTeX?

:- use_module(library(pathnames), [path_concat/3, path_split/3]).
:- use_module(library(system), [get_home/1]).

%:- export(prepare_mathjax/0).
prepare_mathjax :-
	detect_mathjax,
	maybe_symlink_mathjax.

maybe_symlink_mathjax :-
	( has_mathjax(JS) ->
	    % Create a symlink to MathJax (see @pred{using_mathtax})
	    path_split(JS, JSDir, _),
	    absfile_for_aux('MathJax', html, JSLink),
	    copy_file(JSDir, JSLink, [overwrite, symlink])
	; true
	).

:- export(using_mathjax/1).
% Path to the MathJax.js file (it may be relative to the document path).
%
% Note: the path to MathJax in the HTML file can be relative; making
% it work from the web and filesystem.
% TODO: This may not work in all cases, but avoids cumbersome
%       configurations.
using_mathjax(JS) :-
	( has_mathjax(_) ->
	    % Uses the symbolic link created in @pred{prepare_mathjax}
	    JS = 'MathJax/MathJax.js'
	; fail
	).

:- data has_mathjax/1.

detect_mathjax :-
	retractall_fact(has_mathjax(_)),
	( find_mathjax(JS) ->
	    % MathJax.js was found
	    assertz_fact(has_mathjax(JS))
	; no_mathjax_message
        ).

no_mathjax_message :-
	note_message(
             "No MathJax detected. In order to view formulas in the HTML output, "||
             "please install MathJax 1.1 under your public_html/ directory. "||
             "(http://www.mathjax.org/download/)").

% (fails if no mathjax.js is found)
% TODO: This is ad-hoc, use a bundle flag
find_mathjax(JS) :-
	Home = ~get_home,
	path_concat(Home, 'public_html/MathJax/MathJax.js', JS0),
	file_exists(JS0),
	!,
        JS = JS0.

