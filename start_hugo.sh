#!/bin/bash
export hugo_url=http://$(docker-machine ip default)/
docker run --rm -p 1313:1313 -v $(pwd)/site/:/usr/share/blog/ jmm/hugo hugo server --baseURL=${hugo_url} --bind=0.0.0.0
