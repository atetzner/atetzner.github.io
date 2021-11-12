#!/bin/bash

function jekyll() {
    docker run --rm -ti --user "$(id -u):$(id -g)" -v $(pwd):/site bretfisher/jekyll "$@"
}

function jekyll-serve() {
    docker run --rm -ti -p 4000:4000 -v $(pwd):/site bretfisher/jekyll-serve "$@"
}
