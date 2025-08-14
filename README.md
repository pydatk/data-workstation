# data-workstation

_**IMPORTANT**: Please read the README.md and LICENSE files before using. Take a snapshot and backup data before deploying. Test in a non-production environment before deploying._

## What is data-workstation?

`data-workstation` automates management of Ubuntu workstations used for Python data projects.

It installs software, configures the UI, creates a directory framework and project templates, and handles backups.

Links:

- [Website](https://www.pydatk.com/)
- [Discussion](https://github.com/pydatk/data-workstation/discussions)
- [Issues](https://github.com/pydatk/data-workstation/issues)

## Environment

`data-workstation` is compatible with Ubuntu 24 LTS. It is intended for deployment on new, single-user virtual machine installations. 

`data-workstation` can run on the following minimum recommended VMWare Workstation configuration:

- 25GB single file (monolithic) disk
- 4GB RAM
- 2 processors
- No USB device support (optional for security)
- Turned off "Accelerate 3D Graphics" (optional, fixes some display issues)

Recommended options for Ubuntu installation:

- Interactive installation
- Default selection (minimal tools)
- Install third-party/media support
- Use LVM disk encryption

## Installing and updating

The easiest way to install and update `data-workstation` is by cloning the public GitHub repository and running the program straight from there.

To install git: `sudo apt install git`

To clone the `data-workstation` repository into `~/data-workstation`:

```
$ git clone https://github.com/pydatk/data-workstation.git ~/data-workstation/
```

To update (recommended each time you run `data-workstation`):

```
$ git -C ~/data-workstation pull
```

As an alternative to using git, you can also [download the latest release](https://github.com/pydatk/data-workstation/releases).

## Quickstart

Go to the directory where you cloned `data-workstation`:

```
$ cd ~/data-workstation
```

### setup

Run the setup module to apply updates. With the `auto-none` option, you will be asked for confirmation before applying each update.

```
$ ./data-workstation.sh setup auto-none
```

### project

Setup a project:

```
$ ./data-workstation.sh project
```
#### Quarto {#sec-quarto}`

Option: `Add Quarto website to project repository?`

To deploy a Quarto website to the local nginx web server installed by `setup`, see [Deploying Quarto websites](#sec-deploy-quarto)

Note that the Quarto content will be added to `.gitignore` by default (and excluded from your repository). You can easily change this if you want to - see [.gitignore](#sec-gitignore).

#### .gitignore {#sec-gitignore}

Option: `Customize .gitignore?`

Choosing this will add the following to `.gitignore`:

```
# custom
.vscode/
quarto/
deploy-quarto.sh
```

This content will be excluded from your repository by default. You can edit `.gitignore` if you want to include these files. 

For more information see:

- [.vscode/](#sec-vs-code)
- [quarto/](#sec-quarto)
- [deploy-quarto.sh](#sec-deploy-www)

#### VS Code {#sec-vs-code}`

Option: `Create VS Code settings.json and add venv as default Python interpreter?`

#### Additional steps

After setting up a project, there are a few optional additional steps:

- In VS Code, the Python virtual environment interpreter should be selected automatically when you create a Python file. To select it manually, press `F1` then `Python: Select interpreter`. Choose the option `Use Python from python.defaultInterpreterPath setting`. Close then reopen any terminal windows. The name of the Python virtual environment should appear: `(data-workstation-250811-2107) ... $`.
- To install packages using pip, use the python command in the virtual environment explicitly. If pip is called accidentally without an active virtual environment, it will install packages to the global Python.
    - To install a named package: `(intranet-250811-1124) dev@dev:~/projects/intranet/intranet$ ~/venvs/intranet-250811-1124/bin/python -m pip install <<package_name>>`
    - To install all packages in the `requirements.txt` file: `(intranet-250811-1124) dev@dev:~/projects/intranet/intranet$ ~/venvs/intranet-250811-1124/bin/python -m pip install -r requirements.txt`

### backup

Create a backup:

```
$ ./data-workstation.sh project
```

### deploy-www {#sec-deploy-www}

The `deploy-www` module publishes web content in the given input directory to the given output directory and sets permissions for nginx. 

In this example, content will be copied from `my_website` to `published`, and then available via nginx at [http://localhost/published](http://localhost/published):

```
$ ./data-workstation.sh deploy-www /home/data-workstation-inc-all/projects/my_website/ /var/www/html/published/
```

The trailing slashes are necessary, otherwise content will be copied to directory `/var/www/html/published/my_website` instead of `/var/www/html/published`.

#### Deploying Quarto websites {#sec-deploy-quarto}

Any Quarto website output directory can be used as with `deploy-www`.

If you used the Quarto option in `data-workstation project` to setup the website, there will be a `deploy-quarto.sh` file in the project root. Running this will deploy the `_site` output directory to `/var/www/html/yourproject`, available via `http://localhost/yourproject`. You will need to use `quarto render` to create the output directory first.

This process can be automated by setting the `post-render` option in `_quarto.yml`:

```
project:
  type: website
  post-render: ../deploy-quarto.sh
```

## Tools

### dconf_diff

Use `dconf_diff` to identify updated dconf keys/values after making changes to Ubuntu settings. If differences are found, use dconf Editor's search function to find the key(s).

To run:

```
$ cd ~/data-workstation/tools
$ ./dconf_diff.sh
```