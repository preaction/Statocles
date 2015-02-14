
GIT_GITHUB_URL=https://github.com/git/git.git

if [[ ! -d "git" ]]; then
    git clone $GIT_GITHUB_URL git
fi

VERSION=$1
cd git
git checkout $1
make clean && ./configure --prefix="$(pwd)/../versions/$1" --without-gtk --without-tcltk --without-gui && make && make install
cd -
