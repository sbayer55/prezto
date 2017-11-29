Steve's Prezto Fork
===================

Prezto — Instantly Awesome Zsh
==============================

Prezto is the configuration framework for [Zsh][1]; it enriches the command line
interface environment with sane defaults, aliases, functions, auto completion,
and prompt themes.

Installation
------------

Prezto will work with any recent release of Zsh, but the minimum required
version is 4.3.11.

  1. Install Source Code Pro:
    Download Link (zip): https://github.com/adobe-fonts/source-code-pro/archive/variable-fonts.zip
    Install font (Instruction https://github.com/adobe-fonts/source-code-pro#font-installation-instructions)

  2. Clone this repo:

     ```console
     git clone https://github.com/sbayer55/prezto.git ~/.zprezto
     ```

  3. Install dependancies:
    
    ```console
    cd ~/.zprezto
    git submodule update --init --recursive
    ```

  4. Run setup:

     ```console
     cd ~/.zprezto
     ./setup.sh
     ```

  5. Profit

### Troubleshooting

If you are not able to find certain commands after switching to *Prezto*,
modify the `PATH` variable in *~/.zprofile* then open a new Zsh terminal
window or tab.

Updating
--------

Run `zprezto-update` to automatically check if there is an update to zprezto.
If there are no file conflicts, zprezto and its submodules will be
automatically updated. If there are conflicts you will instructed to go into
the `$ZPREZTODIR` directory and resolve them yourself.

To pull the latest changes and update submodules manually:

```console
cd $ZPREZTODIR
git pull
git submodule update --init --recursive
```

Usage
-----

Prezto has many features disabled by default. Read the source code and
accompanying README files to learn of what is available.

### Modules

  1. Browse */modules* to see what is available.
  2. Load the modules you need in *~/.zpreztorc* then open a new Zsh terminal
     window or tab.

### Themes
*Note*: Only the paradox theme has been enhanced for use with kubectl

  1. For a list of themes, type `prompt -l`.
  2. To preview a theme, type `prompt -p name`.
  3. Load the theme you like in *~/.zpreztorc* then open a new Zsh terminal
     window or tab.

     ![sorin theme][2]

### External Modules

  1. By default modules will be loaded from */modules* and */contrib*.
  2. Additional module directories can be added to the
     `:prezto:load:pmodule-dirs` setting in *~/.zpreztorc*.

     Note that module names need to be unique or they will cause an error when
     loading.

     ```console
     zstyle ':prezto:load' pmodule-dirs $HOME/.zprezto-contrib
     ```

Customization
-------------

The project is managed via [Git][3]. It is highly recommended that you fork this
project; so, that you can commit your changes and push them to [GitHub][4] to
not lose them. If you do not know how to use Git, follow this [tutorial][5] and
bookmark this [reference][6].

Resources
---------

The [Zsh Reference Card][7] and the [zsh-lovers][8] man page are indispensable.
Source Code Pro: https://github.com/adobe-fonts/source-code-pro

License
-------

This project is licensed under the MIT License.

[1]: https://github.com/sorin-ionescu/prezto
[2]: http://www.zsh.org
[3]: http://i.imgur.com/nrGV6pg.png "sorin theme"
[4]: http://git-scm.com
[5]: https://github.com
[6]: http://gitimmersion.com
[7]: http://gitref.org
[8]: http://www.bash2zsh.com/zsh_refcard/refcard.pdf
[9]: http://grml.org/zsh/zsh-lovers.html
