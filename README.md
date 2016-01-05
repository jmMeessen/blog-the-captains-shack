# The Captain's Shack blog

This is the home of the blog hosted on the Captain's Shack.

The blog is a static site generated with [Hugo](http://www.gohugo.io/) from the sources
stored in this repository.

To test the site, just run `xyz`.

to generate an empty site docker run --rm -v /Users/jmm/work/blog-the-captains-shack/data/:/usr/share/blog/  jmm/hugo hugo new site .

docker build -t jmm/blog .
