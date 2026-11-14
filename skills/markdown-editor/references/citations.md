# Citations

Default rules for repositories with no citation convention of their own.
Match the weight of the citation to the source, and keep an open-world
tone: state what things do, adding a negation only where it prevents a
likely misreading.

## Web pages, docs, repositories and software

Link the source inline, where the claim appears, with descriptive link
text. Point to a pinned version (a tag or commit) when one exists, so the
link keeps saying what it said. A reference list and publication years are
unnecessary here.

```markdown
Style comes from the [markdownlint-cli2 configuration](https://github.com/DavidAnson/markdownlint-cli2/tree/v0.24.1#configuration).
```

## Publications

For articles, papers, books, standards and reports, use APA 7:

- cite inline as `([Author, Year])`, a shortcut reference link; when the
  year is unknown, omit it (`([Author])`) instead of writing "n.d.", and
  tell same-author, same-year sources apart with letters (`2026a`);
- end the document with a `## References` section listing only the cited
  publications, alphabetically, each as `[Author, Year] <APA 7 reference>`,
  followed by the link definitions `[Author, Year]: <url>`;
- link the DOI where there is one.

```markdown
Readers skim headings first ([Nielsen, 2006]).

## References

[Nielsen, 2006] Nielsen, J. (2006). *F-shaped pattern for reading web
content*. Nielsen Norman Group.

[Nielsen, 2006]: https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content-discovered/
```

A document that cites both kinds lists only the publications under
`## References`; web sources stay as inline links.
