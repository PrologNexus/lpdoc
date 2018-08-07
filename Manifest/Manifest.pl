:- bundle(lpdoc).
depends([core]).
alias_paths([
    lpdoc = 'src',
    library = 'lib',
    lpdoc_etc = 'etc'
]).
cmd('lpdoc', [main='cmds/lpdoccl']).
lib('src').
lib('lib').
manual('lpdoc', [main='doc/reference/SETTINGS.pl']).
readme('INSTALLATION', [main='doc/readmes/INSTALLATION_LPDOC.lpdoc']).
readme('CHANGELOG', [main='doc/readmes/CHANGELOG_LPDOC.pl']).
