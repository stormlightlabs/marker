---
title: "TODO List"
updated: 2026-05-13
---

## Parking Lot

### Ad Blocking

- Add EasyPrivacy as a bundled filter list

### Bookmarks

- Bookmark folders with a top-level `/bookmarks` route for listing and managing them.
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

- Loading shouldn't be a spinner on top of the WebView -> we should show a progress bar
  at the bottom of the screen
- Recent pages in the "Home" screen should be changed:
  - Show the favicon if available, otherwise show a placeholder with the first letter of
    the domain name.
  - Should be "Recently Annotated" instead of "Recently Visited"
