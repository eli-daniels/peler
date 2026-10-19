flow <- c("flowchart LR", "  A[Mermaid text] --> B{Valid?}", "  B -->|yes| C[SVG]")

test_that("pele() renders a diagram to SVG", {
  d <- pele(flow, id = "x")
  expect_s3_class(d, "pele")
  expect_equal(d$type, "flowchart")
  expect_match(d$svg, "^<svg ")
  expect_match(d$svg, "Mermaid text", fixed = TRUE)
  expect_gt(d$width, 0)
})

test_that("the default id comes from the text", {
  expect_identical(pele(flow)$id, pele(paste(flow, collapse = "\n"))$id)
  expect_false(identical(pele(flow)$id, pele("flowchart LR\n  A --> C")$id))
  # The hash is of the text's bytes, so the id is the same in every session and R version
  expect_identical(pele("flowchart LR\n  A --> B")$id, "pele-06852082")
})

test_that("font_family reaches the SVG", {
  d <- pele(flow, font_family = '"Fira Sans", sans-serif')
  expect_match(d$svg, "Fira Sans", fixed = TRUE)
})

test_that("pele() explains bad arguments and diagrams pele can't render", {
  expect_snapshot(error = TRUE, {
    pele(1)
    pele("  ")
    pele(flow, font_size = "big")
    pele(flow, theme = list(fg = "red"))
    pele("not a diagram")
    pele("sequenceDiagram\n  Alice ->> : hi")
    pele("flowchart LR\n  A --> B[oops")
    pele(paste0("flowchart LR\n", strrep("  A --> B\n", 20000)))
  })
})

test_that("pele() warns when pele rejects the font family", {
  expect_snapshot(d <- pele(flow, font_family = "Inter; color: red"))
  expect_no_warning(pele(flow, font_family = "sans-serif"))
})

test_that("render errors have a class per pele error code", {
  expect_error(pele("not a diagram"), class = "peler_error_unsupported_diagram")
  expect_error(pele("sequenceDiagram\n  Alice ->> : hi"), class = "peler_error_syntax")
})

test_that("an error message is one plain string, which shiny can print", {
  err <- tryCatch(pele("sequenceDiagram\n  Alice ->> : hi"), error = identity)
  expect_type(err$message, "character")
  expect_length(err$message, 1)
  expect_null(names(err$message))
  expect_match(err$message, "Expecting 'ACTOR'", fixed = TRUE)
})
