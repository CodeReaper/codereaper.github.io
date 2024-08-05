---
title: Moving To Hugo
date: 2024-07-28T00:00:00+02:00
draft: true
---

## What Happened?

A long time ago I tinkered with setting up at home services like git, ssh, wikipedia, dns and many more. Over the years these services was one by one made obsolete. The setup I had running was a mac mini with [ESXi](https://en.wikipedia.org/wiki/VMware_ESXi) that booted up several [FreeBSD](https://www.freebsd.org/) that each provided a service.

The mini died. At the time of death it was still providing ssh access and hosting git repositories. It had also been so long that I had even looked at the repository for this blog that I had no checked out copies on any machine.

The only choice now was either to scrap the blog and begin anew or recreate it.

## The Plan

1. Download the actual Jekyll output files from the old blog
1. Create fresh Jekyll base layout
1. Copy and convert old files back into Markdown
1. Apply the corrections mentioned in the first blog post

Six hours into the plan I had remembered that Ruby (the language Jekyll uses) is terrible and the theme I was using is now horribly outdated.

Everything was pain and in near desperation I looked for an alternative.

## Hugo

I found [Hugo](https://gohugo.io). It does the same job. It has mostly the same type of theme integration. Best of all it is written in [Go](https://go.dev), so it is fast and will not break on _every_ single version update.

Hugo also seems to much customizable provided you are familiar with Go.

## Recreation

Since I am no longer using Jekyll recreating the source code will be slightly more difficult.

### The Theme

I was lucky enough that the theme [Hyde](https://github.com/spf13/hyde/tree/208a9e3f6bfcfd44f4ee93f5eaba22119b00ffe4) had been ported many years ago. Alas an old theme goes come with problems that needs a lot of "intervention", so instead of adding it as a git submodule. Doing so means I will not easily get updates, but means I can just remove files instead of making sure I override what those files do.

I am left with the directory `themes/hyde/...` that contains only the unaltered files.

### Pretty URLs

To keep blog post urls the same as the old blog was fairly easy. Hugo has a configuration file in the root of the repository named `hugo.yaml`, which can be configured with:

```yaml
permalinks:
  page:
    posts: blog/:year/:slug/
```

The non-post urls defaults to pretty urls like `/about/`. Easy.

### Paginator

I dislike the `Read more` functionality and without those links showing multiple posts per page is just odd.

Instead of recreating an exact match of the old blog I went with always showing a single full post. The full post has links to the next and previous posts. To achieve this I had to manipulate some Go template layouts. The relevant layouts:

- `layouts/_default/list.html` - House keeping, since it is no longer in use
- `layouts/_default/single.html` - Update to show a single post with next and previous links

The `list.html` file could be an empty file, since there are no listing of posts anywhere.

The `single.html` file I have appended the following code snippet to display a previous link, if one exist, a next link, if one exist and a dash in between the two links if they both exist.

```go-html-template
{{ $hasNext := and .Page.Next (eq .Page.Next.Type "posts") }}
{{ $hasPrev := and .Page.Prev (eq .Page.Prev.Type "posts") }}

{{ if $hasNext }}
  <a href="{{ .Page.Next.Permalink }}">« {{ .Page.Next.Title }}</a>
{{ end }}
{{ if and $hasNext $hasPrev }}
&mdash;
{{ end }}
{{ if $hasPrev }}
  <a href="{{ .Page.Prev.Permalink }}">{{ .Page.Prev.Title }} »</a>
{{ end }}
```

Note that the variables set up in the beginning checks the type of the next and previous pages, since non-post pages are considered eligible next or previous pages.

### Redirection

In the previous section I claimed:

> ... there are no listing of posts anywhere.

... and you may have thought "What about the index then?"

I do have to handle the index page, but I am going to cheat and have the index redirect to the latest post instead!

The `layouts/index.html` file therefore is as simple as the following code snippet.

```go-html-template
<!DOCTYPE html>
<html lang="en-us">
  <head>
    <meta name="robots" content="noindex">
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    {{ $firstPost := first 1 (where .Site.RegularPages "Type" "posts") }}
    {{ range $firstPost }}
      <meta http-equiv="refresh" content="0; url={{ .RelPermalink }}" />
    {{ end }}
  </head>
</html>
```

In the original post about Jekyll I wrote about taking care of old pretty URL and not breaking them. The index file there has just been put in place only sets up redirection from `/` to `/blog/YYYY/latest-post`. The old blog considered `/blog/` as a valid entry point too.

Luckily Hugo supports defining an alias for a page in its frontmatter, also in otherwise empty index pages. This allows me to generate a redirection to the latest post at both `/` and `/blog/` with the following snippet:

```go-html-template
---
aliases:
 - /blog
---
```

### Code Highlights

FIXME

### Assets

FIXME

Extra copy - builtin

## GitHub

FIXME

### Free Safe Hosting

FIXME custom domain too

### Automatic Deployment

FIXME
