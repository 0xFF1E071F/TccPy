: @echo off
git config --global user.email qgbcs1@gmail.com
git config --global user.name QGB

git config --global core.filemode false
git config --global credential.helper store

git remote add q https://github.com/qgb/tccpy
git remote add cq https://coding.net/u/qgb/p/tccpy/git
git add -A
git commit -m %*
git push ctp master 
git push gtp master 