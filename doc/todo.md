---
title: "TODO List"
updated: 2026-05-13
---

## Parking Lot

### Ad Blocking

- Add EasyPrivacy as a bundled filter list

### Bookmarks

- [x] Bookmark folders with a top-level `/bookmarks` route for listing and managing them.
  - /bookmarks/:id -> folder or bookmark details
  - /bookmarks/:id/edit -> edit bookmark or folder (sheet)
  - /bookmarks/export?selected=[] -> Export to Netscape bookmarks format (selected is
    optional and can be a list of bookmark ids, if not provided, export all bookmarks)

      ```html
      <!DOCTYPE NETSCAPE-Bookmark-file-1>
      <!-- This is an automatically generated file. -->
      <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
      <TITLE>Bookmarks</TITLE>
      <H1>Bookmarks</H1>

      <DL><p>
      <DT><H3 ADD_DATE="1710000000" LAST_MODIFIED="1710000000">Programming</H3>
      <DL><p>
          <DT><A HREF="https://www.rust-lang.org/" ADD_DATE="1710000000">Rust</A>
          <DT><A HREF="https://developer.mozilla.org/" ADD_DATE="1710000000">MDN Web Docs</A>
      </DL><p>

      <DT><A HREF="https://example.com/article" ADD_DATE="1710000000">Example Article</A>
      </DL><p>
      ```

### Social integration

- Integrate with [semble](https://semble.so/) & [margin](https://margin.at)
- [Hypothes.is](https://web.hypothes.is/) integration

### WebView

- Make bookmarks & annotated pages bookmark folder aware

### Address Bar

- We need a refresh button in the address bar
- Text input: resets when focus is lost, should retain the URL until the user starts typing a new one.
- Fuzzy history search -> rely on favicon cache
