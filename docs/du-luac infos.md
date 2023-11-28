
# Installing or Building from Git

With the change to TypeScript starting on version 1.0.0, you are not able to install the CLI directly from GitHub with NPM alone anymore, as no compiled results are bundled into the Git repository. Building and installing from source is not hard, though, and requires no extra tools. There's how to do it:

    Remove any existing installs by running npm uninstall -g @wolfe-labs/du-luac
    Clone the repository from Git, using git clone https://github.com/wolfe-labs/DU-LuaC.git and switch to the newly created directory
    Optionally, switch to the desired Git branch you want to try out. Currently main is used for active development and is not stable. Releases are marked with tags.
    Install the required dependencies by running npm install, this will install everything you need to run the CLI yourself
    Run npm run pre-release to build the CLI for production. It will update the Codex to the latest version and compile all TypeScript sources. Optionally, you can also run npx tsc to build only the TypeScript sources.
    Finally, run npm link to link the du-lua command to your new install.

With the steps above done, you should be able to run du-lua directly from your cloned directory.
