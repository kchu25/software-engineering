<!--
Add here global page variables to use throughout your website.
-->
+++
author = "Shane Chu"
mintoclevel = 2

# Add here files or directories that should be ignored by Franklin, otherwise
# these files might be copied and, if markdown, processed by Franklin which
# you might not want. Indicate directories by ending the name with a `/`.
# Base files such as LICENSE.md and README.md are ignored by default.
ignore = ["node_modules/"]

# RSS (the website_{title, descr, url} must be defined to get RSS)
generate_rss = true
website_title = "Shane Chu's website"
website_descr = "Shane Chu's website"
website_url   = "https://kchu25.github.io/"
+++

@def prepath=""
<!-- @def div_content = "container" -->

<!--
Add here global latex commands to use throughout your pages.
-->
\newcommand{\R}{\mathbb R}

\newcommand{\xbm}{\bm x}
\newcommand{\ubm}{\bm u}
\newcommand{\ybm}{\bm y}
\newcommand{\zbm}{\bm z}
\newcommand{\fbm}{\bm f}
\newcommand{\sbm}{\bm s}
\newcommand{\dbm}{\bm d}
\newcommand{\bbm}{\bm b}
\newcommand{\Pbm}{\bm P}
\newcommand{\Abm}{\bm A}

\newcommand{\scal}[1]{\langle #1 \rangle}
