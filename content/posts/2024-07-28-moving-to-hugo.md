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

FIXME

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

### Redirection

FIXME

```go
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
