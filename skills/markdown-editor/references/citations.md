# Citations

Default rules for projects with no citation convention of their own. Match
the weight of the citation to the source, and keep an open-world tone:
state what things do, adding a negation only where it prevents a likely
misreading.

## Websites, docs, repositories and software

Link the source inline, where the claim appears, with descriptive link text.
Add no year. Don't pin a tag or commit by default, so the Markdown source
stays easy to read; pin a version only when the author or the editing agent
asks for it.

```markdown
Style comes from the [markdownlint-cli2 configuration](https://github.com/DavidAnson/markdownlint-cli2#configuration).
```

## Authored works

Use APA 7 for journal articles, papers, books, book chapters, reports,
standards, conference sessions, theses, preprints, datasets, blog posts,
articles on webpages, videos and podcast episodes.

Cite in the text with a clickable shortcut reference link:

- one author: `([Author, Year])`; two: `([Author & Author, Year])`; three or
  more: `([Author et al., Year])`; a group author: its full name;
- unknown date: `([Author, n.d.])`;
- same author and year: `2026a`, `2026b`;
- works whose short forms collide (e.g. two `Smith et al., 2026` with
  different coauthors): name as many authors as needed to tell them apart,
  so each label, and its link, is unique;
- no DOI or URL (e.g. a print book): plain `(Author, Year)`, no link
  definition.

Mark italics with `*...*`, each span on one line. Write a DOI as
`https://doi.org/...`; use the URL when there is none. Add "Retrieved Month
D, YYYY, from `<url>`" only for content designed to change over time.
Patterns follow the APA Style common reference examples guide
([American Psychological Association, 2025]):

| Type               | Pattern                                                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| Journal article    | Author, A. A., & Author, B. B. (Year). Title of article. *Journal Name*, *volume*(issue), pages. DOI                     |
| Book               | Author, A. A. (Year). *Title of book*. Publisher. DOI                                                                    |
| Book chapter       | Author, A. A. (Year). Title of chapter. In E. E. Editor (Ed.), *Title of book* (pp. x–y). Publisher. DOI                 |
| Report             | Author, A. A. (Year). *Title of report*. Publishing Group. URL                                                           |
| Group report       | Group Name. (Year). *Title of report*. URL                                                                               |
| Standard           | Organization. (Year). *Title* (Standard No.). Publisher. URL                                                             |
| Conference session | Author, A. A. (Year, Month D–D). *Title of session* [Conference session]. Conference Name, City, ST, Country. URL        |
| Thesis             | Author, A. A. (Year). *Title* (Publication No. x) [Doctoral dissertation, University]. Database.                         |
| Preprint           | Author, A. A. (Year). *Title of preprint*. Repository. URL                                                               |
| Dataset            | Author, A. A. (Year). *Title of dataset* (Version) [Data set]. Publisher. DOI                                            |
| Blog post          | Author, A. A. (Year, Month D). Title of post. *Blog Name*. URL                                                           |
| Webpage article    | Author, A. A. (Year, Month D). *Title of page*. Site Name. URL                                                           |
| Changing webpage   | Group Name. (n.d.). *Title of page*. Retrieved Month D, YYYY, from URL                                                   |
| Video              | Channel or Author. (Year, Month D). *Title of video* [Video]. Site Name. URL                                             |
| Podcast episode    | Host, A. A. (Host). (Year, Month D). Title of episode (No. x) [Audio podcast episode]. In *Podcast Name*. Publisher. URL |

## References section

End the document with `## References` when it cites authored works. Sort
entries alphabetically by the first author's surname (or the group name).
Write each as `- [Author, Year] <APA 7 reference>`, and put the link
definition `[Author, Year]: <url or https://doi.org/...>` below the list, so
the source stays readable; an entry with no DOI or URL has no label or
link definition. A significant website or repository may also
appear in the list as a plain inline link with a few words on what it
covers.

```markdown
Readers skim headings first ([Nielsen, 2006]).

## References

- [Nielsen, 2006] Nielsen, J. (2006, April 16).
  *F-shaped pattern for reading web content*. Nielsen Norman Group.

[Nielsen, 2006]: https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content-discovered/
```

## References

- [American Psychological Association, 2025]
  American Psychological Association. (2025).
  *APA Style common reference examples guide*.

[American Psychological Association, 2025]: https://apastyle.apa.org/instructional-aids/reference-examples.pdf
