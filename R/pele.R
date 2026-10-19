# pele ----

#' Render a Mermaid diagram
#'
#' @description
#' Renders Mermaid diagram text to SVG with the bundled 'pele' library. The
#' result prints as inline SVG in HTML documents, the RStudio viewer and
#' 'shiny' (`renderUI()`), as a PDF or PNG figure in other 'knitr' output
#' formats, and saves to a file with [pele_save()].
#'
#' Fonts are set here because pele measures labels in them to lay out the
#' diagram. Colours are CSS variables, set with [pele_theme()], and can
#' change without rendering again.
#'
#' @param text Mermaid diagram text. A character vector is joined with
#'   newlines, one element per line.
#' @param font_family,font_size Font family and size in pixels that labels
#'   are measured and drawn in. `NULL` uses the 'pele' defaults (`sans-serif`,
#'   16). Widths are estimated from Arial metrics, so a font much wider than
#'   Arial can overflow its boxes.
#' @param theme A [pele_theme()] or `NULL`. Defaults to the `peler.theme`
#'   option, so a document can set it once.
#' @param id Prefix of the ids inside the SVG. The default comes from a hash
#'   of `text`. See Details.
#'
#' @details
#' ## Ids
#'
#' 'pele' uses `id` for two things:
#'
#' - When the diagram has an `accTitle` or `accDescr`, the SVG holds a
#'   `<title>` and `<desc>` with ids `{id}-title` and `{id}-desc`, which screen
#'   readers find through `aria-labelledby` and `aria-describedby`.
#' - Cynefin diagrams seed their random region boundaries with it, so the id
#'   changes how they look.
#'
#' Ids must be unique on a HTML page. The default, `pele-` and the start of
#' an MD5 hash of `text`, gives the same id to the same text in every session,
#' so a document renders the same SVG every time, including from the 'knitr'
#' cache. In `pele` chunks the id is `pele-` and the chunk label instead.
#'
#' Things to know when you set `id` yourself, or rely on the default:
#'
#' - Two diagrams with the same text get the same default id. Their titles
#'   and descriptions are the same too, so a screen reader still reads the
#'   right text, but the page has duplicate ids, which HTML validators report.
#'   Give one of them its own `id` if that matters.
#' - Reusing one custom `id` for different diagrams on a page makes a screen
#'   reader announce the first diagram's title for all of them.
#' - Changing the `id` of a Cynefin diagram redraws its boundaries.
#'
#' @return A `pele` object: a list with `svg` (a string), `width` and
#'   `height` in pixels, the diagram `type`, `theme` and `id`.
#' @export
#' @examples
#' d <- pele(c(
#'   "flowchart LR",
#'   "  A[Mermaid text] --> B[SVG]"
#' ))
#' d$type
#' d$width
pele <- function(text,
                 font_family = NULL,
                 font_size = NULL,
                 theme = getOption("peler.theme"),
                 id = NULL) {
  if (!is.character(text) || anyNA(text)) {
    peler_abort("{.arg text} must be a character vector without missing values, not {.obj_type_friendly {text}}.")
  }
  if (!nzchar(trimws(paste(text, collapse = "")))) {
    peler_abort("{.arg text} can't be empty.")
  }
  check_string(font_family, allow_null = TRUE)
  check_number(font_size, allow_null = TRUE)
  check_string(id, allow_null = TRUE)
  check_theme(theme)
  text <- paste(text, collapse = "\n")
  # The id comes from the text, not a counter or a random UUID, so the same document
  # renders the same SVG every time, including from the knitr cache, and adding a diagram
  # does not renumber the others. Two diagrams share an id only if their text is the
  # same, and then their shared accessible title and description match anyway.
  id <- id %||% paste0("pele-", substr(cli::hash_md5(text), 1, 8))
  options <- list(fontFamily = font_family, fontSize = font_size, idPrefix = id)
  # V8 would send a NULL to pele as an empty object, not as a missing option, and pele
  # would use it: a NULL font_size draws `font:[object Object]px`
  options <- options[!vapply(options, is.null, logical(1))]

  out <- js_context()$call("peler_render", text, options)
  if (!isTRUE(out$ok)) abort_render(out)

  # pele draws in sans-serif, without an error, when it rejects a font family. Asking
  # for sans-serif gives the same SVG, so that case is not a fallback.
  fell_back <- grepl("var(--pele-font,sans-serif)", out$svg, fixed = TRUE)
  if (!is.null(font_family) && trimws(font_family) != "sans-serif" && fell_back) {
    cli::cli_warn(c(
      "Can't use {.arg font_family} {.val {font_family}}.",
      x = "It must be a comma-separated list of font names, quoted or not.",
      i = "Labels were measured and drawn in {.val sans-serif}."
    ))
  }

  structure(
    list(svg = out$svg, width = out$width, height = out$height, type = out$type, theme = theme, id = id),
    class = "pele"
  )
}

# js_context ----

#' The V8 context holding 'pele', created on first use
#' @noRd
js_context <- function() {
  if (is.null(the$ctx)) {
    ctx <- V8::v8()
    ctx$source(system.file("js", "pele.global.js", package = "peler"))
    # Returns errors as values: a thrown PeleError would reach R as a bare message.
    ctx$eval("
      function peler_render(src, opts) {
        try {
          var r = pele.render(src, opts);
          return { ok: true, svg: r.svg, width: r.width, height: r.height, type: r.type };
        } catch (e) {
          return { ok: false, message: String(e.message), code: e.code || null,
                   type: e.type || null, line: e.line || 0, snippet: e.snippet || '' };
        }
      }
    ")
    the$ctx <- ctx
  }
  the$ctx
}

#' Turn a PeleError, returned as a list by `peler_render()`, into an R error
#' @noRd
abort_render <- function(err, call = rlang::caller_env()) {
  diagram <- if (is.null(err$type)) "the diagram" else paste("the", err$type, "diagram")
  code <- err$code %||% "unknown"
  class <- paste0("peler_error_", gsub("-", "_", code))

  # Each peler_abort() below ends the function: it signals an error and never returns.
  if (code == "unsupported-diagram") {
    peler_abort(
      c(
        "Can't find a diagram type in {.arg text}.",
        i = "The first line names the type, such as {.code flowchart LR} or {.code sequenceDiagram}.",
        i = "See the supported types at {.url https://pele.run}."
      ),
      class = class, call = call
    )
  }
  if (code == "limit") {
    # pele's message here names the limit that was hit, and has no snippet to strip
    peler_abort(
      c(
        "Can't render a diagram this large.",
        x = "{err$message}",
        i = "pele limits the size of the text and of the SVG, see {.url https://pele.run/security}."
      ),
      class = class, call = call
    )
  }

  # pele's message repeats the line number and the snippet, which get their own bullets here
  message <- err$message
  if (nzchar(err$snippet)) message <- sub(err$snippet, "", message, fixed = TRUE)
  message <- sub("^(Parse|Lexical) error on line [0-9]+[:.]", "", message)
  message <- trimws(gsub("\\s+", " ", message))

  # The source line, then a caret under the error. None when the error is at the end of
  # the text, where the line is empty.
  snippet <- strsplit(err$snippet, "\n", fixed = TRUE)[[1]]
  if (length(snippet) && !nzchar(trimws(snippet[1]))) snippet <- character()
  # Non-breaking spaces, which cli does not collapse, keep the caret under its column
  snippet <- gsub(" ", intToUtf8(160L), snippet, fixed = TRUE)

  where <- if (err$line > 0 && length(snippet)) "On line {err$line}:" else if (err$line > 0) "On line {err$line}, at the end of the text."
  peler_abort(
    c(
      if (code == "syntax") "Can't parse {diagram}." else "Can't render {diagram}.",
      x = "{message}",
      i = where,
      bullets(snippet, " ")
    ),
    class = class, call = call
  )
}

the <- new.env(parent = emptyenv())
