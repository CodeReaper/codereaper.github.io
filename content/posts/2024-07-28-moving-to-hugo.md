---
title: Moving To Hugo
date: 2024-07-28T00:00:00+02:00
draft: false
---

## What Happened?

A long time ago I tinkered with setting up at home services like git, ssh, wikipedia, dns, etc. Over the years these services was one by one made obsolete. The setup I had running was a mac mini with [ESXi](https://en.wikipedia.org/wiki/VMware_ESXi) that booted up several [FreeBSD](https://www.freebsd.org/) images that each provided a service.

The mini died. At the time of death it was still providing ssh access and hosting git repositories. It had also been so long since I had looked at the repository for my blog that I had no checked out copies on any machine.

The only choice now was either to scrap the blog and begin anew or recreate it.

## The Plan

1. Download the actual Jekyll output files from the old blog
1. Create fresh Jekyll base layout
1. Copy and convert old files back into Markdown
1. Apply the corrections mentioned in the first blog post

Six hours into the plan I had remembered that Ruby (the language Jekyll uses) is terrible and found out the theme I was using is now horribly outdated.

Everything was painful and in near desperation I looked for an alternative.

## Hugo

I found [Hugo](https://gohugo.io). It does the same job. It has mostly the same type of theme integration. Best of all is that it is written in [Go](https://go.dev). I knew Go is fast and will not break on _every_ single version update or dependency change.

Hugo also seems to be much customizable provided you are familiar with Go.

However since I am no longer using Jekyll that means recreating the source code will be slightly more difficult.

### Hugo and the Old Theme

I was lucky enough that the theme [Hyde](https://github.com/spf13/hyde/tree/208a9e3f6bfcfd44f4ee93f5eaba22119b00ffe4) had been ported to Hugo many years ago. Alas an old theme does come with problems that needs a lot of "intervention" and I opted out of adding it as a git submodule which seems to be the recommended way of integrating themes. Doing so means I will not easily get updates, but does mean I can just remove files instead of making sure I override everything what those files do.

Thus I am left with the directory `themes/hyde/...` that contains only the unaltered files.

I found a problem when I used the Hyde theme originally that I described in the my original [first post](https://codereaper.com/blog/2014/getting-to-know-jekyll-and-hyde/) as:

> Other users of Hyde may notice the layout looks slightly different. I had to make the sidebar area larger since the CodeReaper name is too long, especially in comparison to the name Hyde. 

I still do not want my name to be split into multiple parts, so I have added a link to a stylesheet in the hook made available by the theme to override some of its styles.

### Hugo and the Pretty URLs

To keep blog post urls the same as the old blog was fairly easy. Hugo has a configuration file in the root of the repository named `hugo.yaml`, which can be configured with:

```yaml
permalinks:
  page:
    posts: blog/:year/:slug/
```

The non-post urls defaults to pretty urls like `/about/`. Easy.

### Hugo and the Reworking of Paginating

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

### Hugo and the Redirection for Consistency

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

In the original post about Jekyll I wrote about taking care of old pretty URL and not breaking them. The index file above only sets up redirection from `/` to `/blog/YYYY/latest-post`. The old blog considered `/blog/` as a valid entry point too.

Luckily Hugo supports defining an alias for a page in its frontmatter, also in otherwise empty index pages. This allows me to generate a redirection to the latest post at both `/` and `/blog/` with the following snippet:

```go-html-template
---
aliases:
 - /blog
---
```

### Hugo and the Highlights of Code

It turns out that code highlighting is a whole new beast in Hugo.

There is support for quite a lot of [lexers with Chroma](https://gohugo.io/content-management/syntax-highlighting/#list-of-chroma-highlighting-languages), but the syntax highlighting is just the beginning. There are [options](https://gohugo.io/content-management/syntax-highlighting/#highlight-shortcode) that allows for line numbering, actual highlighting specific lines, etc. You can even preview the syntax highlighting of some sample code with this [site xyproto](https://xyproto.github.io/splash/docs/) made.

Consider the following markdown:

````txt
```go {linenos=table,hl_lines=[5,"10-13"],linenostart=28}
func download(flags *Flags, service Service) error {
	if err := flags.validate(); err != nil {
		return err
	}

	mimeType, err := lookupMimeType(flags.Format)
	if err != nil {
		return err
	}

	resp, err := service.download(flags.DocumentId, mimeType)
	if err != nil {
		return err
	}

	return handleResponse(resp, flags.Output)
}
```
````

This will produce the following output:

```go {linenos=table,hl_lines=[6,"11-14"],linenostart=28}
func download(flags *Flags, service Service) error {
	if err := flags.validate(); err != nil {
		return err
	}

	mimeType, err := lookupMimeType(flags.Format)
	if err != nil {
		return err
	}

	resp, err := service.download(flags.DocumentId, mimeType)
	if err != nil {
		return err
	}

	return handleResponse(resp, flags.Output)
}
```

### Hugo and the Assets

When I built the original blog with Jekyll I made sure that assets were grouped per post. I do not have to really do anything special to have assets grouped with the post they belong to with Hugo. You are supposed to place an asset with `contents/posts/name-of-post/asset.file` and refer to said asset in markdown with `[asset](asset.file)`.

That did however pose a problem if anyone had linked directly to an asset in any of my old posts. There did not seem to be any way of redirecting to its new location or automatically duplicating the file. I am going to cheat again. You simply manually duplicate these assets by coping them to `static/path-it-had/asset.file`.

## GitHub

Losing your code is generally not a fun experience. This time to ensure the code is not lost again I am placing it on GitHub. There are many good reasons to do so:

- Free
- High availability
- Well-known
- Et cetera

GitHub has also changed in the 10 years since the old blog was made and now.

GitHub finally offers [unlimited private repositories](https://github.blog/news-insights/product-news/introducing-unlimited-private-repositories/) which, as far as I can recall, was my main reason to not place the blog in GitHub originally. You may find that funny (for multiple reasons) since my [new blog repository](https://github.com/CodeReaper/codereaper.github.io) is in fact not a private repository, but there is good reason for that.

GitHub had pages with support for custom domains, but now also has https support for these custom domains and workflow for automatic deployment.

All these features are free (for public repositories - see, I had a good reason).
