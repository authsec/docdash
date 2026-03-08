# DocDash

This podman image contains a Sphinx documentation toolchain and is used as the main build environment for DocDash. It has support for:

* Full [TeX Live](https://www.tug.org/texlive/) LaTeX installation
* [Markdown](https://daringfireball.net/projects/markdown/)
* [PlantUML](https://plantuml.com/)
* [Draw.io](https://www.drawio.com/) (Headless export support)
* [D2 Language](https://d2lang.com/)
* [Read the Docs Sphinx Theme](https://sphinx-rtd-theme.readthedocs.io/en/stable/)
* [BibTeX](http://www.bibtex.org/) support
* [reveal.js](https://revealjs.com/) support
* [Hovercraft!](https://hovercraft.readthedocs.io/en/latest/usage.html) support
* [Pelican](https://docs.getpelican.com/en/stable/index.html) with Markdown support
* [Hieroglyph](https://hieroglyph.readthedocs.io/en/latest/index.html) support
* [Jupyter Book](https://jupyterbook.org/intro.html) support
* [Excel Table Plus](https://pypi.org/project/sphinxcontrib-excel-table-plus/) support
* [Exceltable](https://pythonhosted.org/sphinxcontrib-exceltable/) support

# Build podman Image

In order for all of this to work, you need to have podman installed. You can [get it here](https://podman-desktop.io/).

You do not need to do this, but if you want to build the image yourself, you can do so with the following command:

``` bash
$#> podman build -t authsec/docdash .

```

You can build and push your own version of the image easily with:

```bash
$#> export VERSION=0.0.8 && podman build -t authsec/docdash:$VERSION . && podman push authsec/docdash:$VERSION

```

# Building for Github release

Tag what you want to release:

```bash
$#> export VERSION=v1.0.0 && git tag $VERSION && git push origin $VERSION

```

Then hit 'Create a new release' on the right side of your github repository.

## Redoing the same version

Delete the tag, tag again, push release button:

```bash
$#> export VERSION=v1.0.0
$#> git tag -d $VERSION && git push --delete origin $VERSION && git tag $VERSION && git push origin $VERSION

```

# Sphinx

Use the following commands to interact with the sphinx container. The commands below show the raw `podman` command. You can however alias the command for convenience.

You can for example set an alias like this in your shell environment:

```bash
$#> alias asphinx='podman run --rm -it -v $(pwd):/workspaces authsec/docdash'

```

This will basically allow you to replace the long `podman run --rm -it -v $(pwd):/workspaces authsec/docdash` command with the command or "alias" `asphinx`.

## Usage

The container comes with Nginx pre-installed. You can start this internal HTTP server by setting the `HTTP_SERVER_PORT` and `HTTP_SERVER_DIR` variables. This is particularly useful in your `.devcontainer/devcontainer.json` configuration file:

```json
{
"name": "My Documentation",
"image": "docker.io/authsec/docdash",
"forwardPorts": [
    8008
],
"containerEnv": {
    "HTTP_SERVER_PORT": "8008"
},
"customizations": {
    "vscode": {
        "extensions": [
            "ms-python.python",
            "ms-toolsai.jupyter",
            "jebbs.plantuml",
            "trond-snekvik.simple-rst",
            "swyddfa.esbonio",
            "mechatroner.rainbow-csv",
            "lextudio.restructuredtext",
            "useblocks.sphinx-needs-vscode",
            "terrastruct.d2"
        ],
        "settings": {
            "editor.suggest.snippetsPreventQuickSuggestions": true,
            "editor.suggest.matchOnWordStartOnly": true,
            "python-envs.alwaysUseUv": true,
            "restructuredtext.builtDocumentationPath": "${workspaceRoot}/build/html",
            "restructuredtext.confPath": "${workspaceFolder}/source",
            "restructuredtext.updateOnTextChanged": "true",
            "restructuredtext.updateDelay": 1000,
            "python.pythonPath": "/opt/venv/bin/python",
            "editor.tabSize": 3,
            "[restructuredtext]": {
                "editor.tabSize": 3
            },
            "sphinx-needs.srcDir": "${workspaceFolder}/source",
            "sphinx-needs.needsJson": "${workspaceFolder}/_build/html/needs.json"
        }
    }
},
"workspaceMount": "source=${localWorkspaceFolder},target=/workspaces/docs,type=bind",
"workspaceFolder": "/workspaces/docs"
}


```

Once inside the container (or devcontainer), you can start the web server using the built-in `rs` (run/restart server) command alias. The server will host the files located in `HTTP_SERVER_DIR` on `HTTP_SERVER_PORT`. You can then reach the documentation from your host operating system at `http://localhost:8008`.

## Sphinx on Windows

If you want to use this container on Windows, you need to slightly tweak the command line to read:

```bash
$#> podman run --rm -it -v ${PWD}:/workspaces authsec/docdash

```

## Create a new Sphinx document

If you want an interactive experience:

```bash
$#> mkdir mydoc
$#> cd mydoc
$#> podman run --rm -it -v $(pwd):/workspaces authsec/docdash sphinx-quickstart 

```

If you used the `alias` command above, the `podman` command will look like:

```bash
$#> asphinx sphinx-quickstart

```

Create a new document e.g. like so:

```bash
$#> asphinx sphinx-quickstart --sep -p "My Demo" -a "Siegfried Sphinx" -v "0.0.1" -r "0.0.1" -l "en" --suffix .rst --epub --master index --ext-intersphinx --ext-todo --makefile -m

```

## Compile a Sphinx document

You can generate your Sphinx document by executing the following command in the directory you created your document (in the above example `mydoc`).

The `clean` argument is not really necessary but might help in certain circumstances; you could also just run `... make html`.

```bash
$#> podman run --rm -it -v $(pwd):/workspaces authsec/docdash make clean html

```

# Diagram & Chart Utilities

The container includes utilities to programmatically generate diagrams.

## Draw.io

A headless wrapper for Draw.io is included. You can export Draw.io XML files to images (PNG, SVG, etc.) natively from the container without a GUI:

```bash
$#> podman run --rm -it -v $(pwd):/workspaces authsec/docdash drawio-headless -x -f png -o diagram.png diagram.drawio

```

## D2 Lang

The D2 declarative diagramming language is installed. You can compile `.d2` files directly:

```bash
$#> podman run --rm -it -v $(pwd):/workspaces authsec/docdash d2 architecture.d2 architecture.svg

```

# Pelican Blog

You can create a new Pelican based blog with the `pelican-quickstart` command using it like:

```bash
$#> podman run --rm -it -v $(pwd):/workspaces authsec/docdash pelican-quickstart

```

If you want to preview your blog with the built in webserver on http://localhost:8000, use the following command:

```bash
$#> podman run --rm -it -v $(pwd):/workspaces -p8000:8000 authsec/docdash pelican -e BIND=0.0.0.0 --autoreload --listen

```

For further information see the [official documentation](https://docs.getpelican.com/en/stable/index.html).

## Using pelican themes

In order to use pelican themes, you have to make them accessible to the container runtime. I suggest mapping the path to `/pelican-themes` inside the container. That way you can configure the theme like `THEME="/pelican-themes/mnmlist"` for example.

You can find a lot of pelican themes [on Github](https://github.com/getpelican/pelican-themes)

I order to keep things separate, I'd suggest setting up, or cloning, the themes at the same level as your blog.

Say you created your blog in a folder called `tmp` you want to clone the themes repository into the `tmp` folder too, so it looks like:

```text
tmp
├── blog
└── pelican-themes

```

You can clone the themes by executing the below command inside the `tmp` folder:

```bash
$#> git clone --recursive [https://github.com/getpelican/pelican-themes](https://github.com/getpelican/pelican-themes) ./pelican-themes

```

The following command must be executed inside your `blog` folder. It will mount the `pelican-themes` folder into the container under `/pelican-themes` where you can reference it in your config.

```bash
$#> podman run --rm -it -v $(pwd):/workspaces -v $(pwd)/../pelican-themes:/pelican-themes -p8000:8000 authsec/docdash pelican -e BIND=0.0.0.0 --autoreload --listen

```

# SASS Compiler

This is especially useful if you're planning to utilize CSS in your presentation. You can generate a CSS from a SCSS source file. You can learn all about that at the [Sass: Sass Basics](https://sass-lang.com/guide) site.

The image contains `pysassc` which is a SASS compiler, and the `pysass` wrapper ([pysass · PyPI](https://pypi.org/project/pysass/)) which allows you to watch the SASS files for changes and compile them automatically when they change.

# Hovercraft Presentations

You can find a description of all the bells and whistles of `hovercraft` where it says [Hovercraft! - Merging convenience and cool!](https://hovercraft.readthedocs.io/en/latest/index.html)

## Compiling a hovercraft document

If you don't want to install all the tooling required to compile a hovercraft presentation, you can use the command below:

```bash
$#> podman run --rm -it -v $(pwd):/workspaces authsec/docdash hovercraft yourinput.rst output

```

## Using the built in web server

If you want to access your presentation through the web server built into `hovercraft`, you also need to expose or publish the port with the `podman` command.

You can run the server using the following command:

```bash
$#> podman run --rm -it -p8000:8000 -v $(pwd):/workspaces authsec/docdash hovercraft positions.rst

```

You can then access your presentation through a web browser by navigating to http://localhost:8000.

# reveal.js Presentations

There seem to be multiple reveal.js implementations available at this point in time. I picked up on two of them.

A fairly new implementation of reveal.js presentations with Sphinx where a good starting point is probably the Github repository [attakei/sphinx-revealjs: Sphinx builder to revealjs presentations](https://github.com/attakei/sphinx-revealjs).

And one that is around for quite a bit but does not seem to be maintained any longer? which can be found in this Github repository [tell-k/sphinxjp.themes.revealjs: A sphinx theme for generate reveal.js presentation. #sphinxjp](https://github.com/tell-k/sphinxjp.themes.revealjs)

## Compiling a reveal.js presentation

Since there are two (or even more implementations) available at the moment I listed the two styles I know about below.

### >>> "attakei" style implementation

You can compile these presentations with:

```bash
$#> podman run --rm -it -v $(pwd):/workspaces authsec/docdash make revealjs

```

### >>> "tell-k" style implementation

You can compile these presentations with:

```bash
$#> podman run --rm -it -v $(pwd):/workspaces authsec/docdash make html

```

as you would compile any ordinary Sphinx document.

# Cleaning Up

If you're done doing your documentation thing, you can clean up your system by executing:

```bash
$#> podman system prune -a

```
