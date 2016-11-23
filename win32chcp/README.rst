This document is also available in the following language:
`Русский </anpol/win32chcp/src/default/README.ru.rst>`__.

----

**win32chcp** is an extension to the
`Mercurial DVCS <http://mercurial.selenic.com/>`__.

The purpose of the extension is to help international Windows users
obtaining readable Mercurial output on their consoles.

Installation
------------

Clone the win32chcp source code somewhere onto your system:

.. code:: sh

    hg clone https://bitbucket.org/anpol/win32chcp

Configure your
`mercurial.ini <http://www.selenic.com/mercurial/hgrc.5.html>`__ to
enable the extension by adding the line with the full path to the
extension file.

.. code:: ini

    [extensions]
    win32chcp = C:/path to extension/hgext/win32chcp.py

The path name should start with a drive letter, delimited with forward
slashes; neither quoting or escaping whitespace characters is required.

Use the following command to double-check that the extension is enabled:

.. code:: sh

    hg help win32chcp

Problem statement
-----------------

-  `Character Encoding on Windows <http://mercurial.selenic.com/wiki/CharacterEncodingOnWindows>`__
   describes the problem, and provides some other suggestions.
-  `Encoding Strategy <http://mercurial.selenic.com/wiki/EncodingStrategy>`__
   discovers some internal details about encoding handling in Mercurial.

How it works
------------

The extension switches the encoding of your console just before you see
any output. The encoding matches the encoding actually used by the
Mercurial on output, so in most cases you will get readable characters
on your display.

Assume you have enabled **win32chcp** on a typical US system with
default settings, where your console encoding is cp437, and the GUI
encoding is windows-1252 (which is also an encoding used by Mercurial by
default).

When you try the following commands:

.. code:: sh

    chcp
    hg
    chcp

you will get the following readable output:

.. code:: sh

    437
    #-- short list of hg commands, encoded in windows-1252
    437

As shown above, the encoding is *restored* upon termination of Mercurial
process. In certain cases, it's not possible or not desired:

.. code:: sh

    chcp
    hg help | more
    chcp

The output will be:

.. code:: sh

    437
    [win32chcp] switching your console encoding into cp1252
    #-- long list of hg commands,
    #-- encoded in windows-1252,
    #-- piped thru `more'
    1252

The command above issues a warning, and leaves your console encoded with
current Mercurial encoding. The effect will remain until you switch the
encoding yourself (using ``chcp 437``), or close your cmd session and
reopen it again.

The reason why it was necessary is that ``hg`` process terminates too
early, while ``more`` is still printing its buffered text to the output,
thus we don't know how to restore console encoding for you.

Our behavior has some interesting consequences:

.. code:: sh

    hg help >help.txt
    type help.txt

Now you're still getting readable results, although the encoding of
``help.txt`` is windows-1252.

We just didn't restore the encoding, following the same reason as the
above.
