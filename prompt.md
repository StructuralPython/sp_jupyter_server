I am looking to create a private Python server accessible from a public IP that will run Jupyter Lab at one URL and VS Code at a different URL. The different application endpoints will be handled by Caddy which will act as a reverse proxy. Access to the public IP will be controlled by Authelia. This server will be hosted on a bunny.net magic container. To achieve this, I need you to create a dockerfile and docker-compose.yml file.

The server must have the following qualities:

* Only two storage volumes to comply with bunny.net's two volume limit
* One storage will represent the home directory of the user. The user must be able to create new, edit, delete new files with it and have sudo access to the file system. It should be based an ubuntu OS. This user volume will be shared and accessible beteen the VS code app and the Jupyter Lab app. It will be called `user-data` and it's mount point will be `/home/engineering` to match the username of `engineering`
* The second volume will be a shared config storage for the applications that require it such as VS Code, Caddy, and authelia. it will be called `app-config`
* The server will use Caddy to manage the multiple applications and their URL endpoints

The server must have the following applications installed:

* curl
* wget
* git
* nano
* graphviz
* sudo
* ca-certificates
* build-essential
* xz-utils
* jre
* tabula
* gh cli app
* quarto
* caddy
* uv

The Python installation must be managed by uv with a virtual environment created in the home directory of the user's storage volume. That venv will have the following Python packages installed:

* structural_starterkit

The virtual environment will be accessible as an IPython kernel with a name of 'sp' and with a display name of "Python 3 (Structural Python)".

Last, this docker image is intended to be distributable to my customers so the email address and the initial password of Authelia must be configurable from variables. Ideally it is configured in a way to take advantage of bunny.net's magic container setup that automatically uses the variables to create a form for the user. If at all possible the initial Python packages that are to be installed in the virtual env will also be conigurable.
