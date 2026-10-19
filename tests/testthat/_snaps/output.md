# pele_save() explains bad arguments

    Code
      pele_save("flowchart LR", "x.png")
    Condition
      Error in `pele_save()`:
      ! `x` must be a diagram, not a string.
      i Make one with `pele()`.
    Code
      pele_save(d, "x.jpg")
    Condition
      Error in `pele_save()`:
      ! `file` must end in '.svg', '.png' or '.pdf'.
      x 'x.jpg' ends in '.jpg'.
    Code
      pele_save(d, "no-such-folder/x.png")
    Condition
      Error in `pele_save()`:
      ! Can't write 'no-such-folder/x.png'.
      x The folder 'no-such-folder' doesn't exist.
    Code
      pele_save(d, "x.png", scale = 0)
    Condition
      Error in `pele_save()`:
      ! `scale` must be positive, not 0.
    Code
      pele_save(d, "x.png", scale = "2")
    Condition
      Error in `pele_save()`:
      ! `scale` must be a single number, not a string.

# pele_save() warns about CSS variables only a web page could define

    Code
      pele_save(d, file, theme = pele_theme(fg = "var(--page-fg)"))
    Condition
      Warning:
      Can't resolve CSS variable `--page-fg` outside a web page.
      i It is drawn as if unset, which is usually black.
      i Give theme values that use `var()` a fallback, such as `var(--my-fg, #1f1f1f)`.

