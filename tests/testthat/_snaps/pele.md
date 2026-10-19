# pele() explains bad arguments and diagrams pele can't render

    Code
      pele(1)
    Condition
      Error in `pele()`:
      ! `text` must be a character vector without missing values, not a number.
    Code
      pele("  ")
    Condition
      Error in `pele()`:
      ! `text` can't be empty.
    Code
      pele(flow, font_size = "big")
    Condition
      Error in `pele()`:
      ! `font_size` must be a single number, not a string.
    Code
      pele(flow, theme = list(fg = "red"))
    Condition
      Error in `pele()`:
      ! `theme` must be a theme or `NULL`, not a list.
      i Make one with `pele_theme()`.
    Code
      pele("not a diagram")
    Condition
      Error in `pele()`:
      ! Can't find a diagram type in `text`.
      i The first line names the type, such as `flowchart LR` or `sequenceDiagram`.
      i See the supported types at <https://pele.run>.
    Code
      pele("sequenceDiagram\n  Alice ->> : hi")
    Condition
      Error in `pele()`:
      ! Can't parse the sequence diagram.
      x Expecting 'ACTOR', got 'TXT'
      i On line 2:
          Alice ->> : hi
        ------------^
    Code
      pele("flowchart LR\n  A --> B[oops")
    Condition
      Error in `pele()`:
      ! Can't parse the flowchart diagram.
      x Expecting 'SQE', 'UNICODE_TEXT', 'TEXT', 'TAGSTART', got '$end'
      i On line 3, at the end of the text.
    Code
      pele(paste0("flowchart LR\n", strrep("  A --> B\n", 20000)))
    Condition
      Error in `pele()`:
      ! Can't render a diagram this large.
      x Diagram source is longer than the limit of 50000 characters.
      i pele limits the size of the text and of the SVG, see <https://pele.run/security>.

# pele() warns when pele rejects the font family

    Code
      d <- pele(flow, font_family = "Inter; color: red")
    Condition
      Warning:
      Can't use `font_family` "Inter; color: red".
      x It must be a comma-separated list of font names, quoted or not.
      i Labels were measured and drawn in "sans-serif".

