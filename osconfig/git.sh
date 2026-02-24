

git config -f ~/.gitconfig_local user.signingkey "key::$(ssh-add -L | grep 'signingkey$')"
git config -f ~/.gitconfig_local gpg.format ssh
git config -f ~/.gitconfig_local commit.gpgsign true

echo "ayatsenkok@gmail.com $(ssh-add -L | grep 'signingkey$')" > ~/.ssh/allowed_signers
