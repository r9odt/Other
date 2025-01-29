git config --global alias.co checkout
git config --global alias.cm "commit -m"
git config --global alias.cs "commit -S"
git config --global alias.csm "commit -S -m"
git config --global alias.st status
git config --global alias.br branch
git config --global alias.hist "log --pretty=format:'%C(cyan)%h%Creset %ad | %s%C(cyan)%d%Creset [%C(bold blue)%an|%ae%Creset] %C(green)(%cr)%Creset [%C(cyan)%G?%Creset] %C(cyan)%GS%Creset' --graph --date=local --all"
git config --global alias.ps push
git config --global alias.pl pull
git config --global alias.ft fetch
git config --global alias.mg merge
git config --global alias.mgs "merge -S"
git config --global alias.cf config
git config --global alias.ad add
git config --global alias.cl clone

git config --global push.autoSetupRemote true

#git config --global credential.helper cache --timeout 60000
git config --global credential.helper store

git config --global core.hooksPath ~/.githooks

git config --global core.eol lf
git config --global core.autocrlf false

#git config --global gpg.format ssh
git config --global commit.gpgsign true
# gpg --full-generate-key --expert
# Change if use includeIf on include configs
#
#[user]
#        email =
#        name =
#        signingkey = key-id
#git config --global user.signingkey ~/.ssh/keys/github-self.key
git config --global gpg.ssh.allowedSignersFile "${HOME}/ssh/allowed_signers"

