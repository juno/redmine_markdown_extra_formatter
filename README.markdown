Redmine Markdown Extra formatter
================================

This is a redmine plugin for supporting Markdown Extra as a wiki format.


What is redmine?
----------------

Redmine is a flexible project management web application.
See [the official site](http://www.redmine.org/) for more details.


What is Markdown Extra?
-----------------------

PHP Markdown Extra is a special version of PHP Markdown implementing some
features currently not available with the plain Markdown syntax.
(excerpt from http://michelf.com/projects/php-markdown/extra/)


Prerequisites
-------------

*  Redmine >= 0.9.4
*  BlueFeather gem - see http://ruby.morphball.net/bluefeather/index_en.html


Installation
------------

1.  Copy the plugin directory into the vendor/plugins directory
2.  Start Redmine
3.  Installed plugins are listed on 'Admin -> Information' screen.


Credits
-------

*  Junya Ogura (http://github.com/juno) for making the change to use BlueFeather library
*  Yuki Sonoda (http://github.com/yugui) did the real work by creating the redmine_rd_formatter
*  Jean-Philippe Lang for making the change to RedMine (based on Yuki's patch) to allow pluggable formatters


Suggestions, Bugs, Refactoring?
-------------------------------

Fork away and create a Github Issue. Pull requests are welcome.
http://github.com/juno/redmine_markdown_extra_formatter/tree/master

