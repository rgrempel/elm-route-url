#! /bin/sh

mkdir -p build
elm-make --yes MainWithFullUrl.elm --output build/MainWithFullUrl.html
elm-make --yes MainWithJustHash.elm --output build/MainWithJustHash.html
elm-make --yes MainWithOldAPI.elm --output build/MainWithOldAPI.html
