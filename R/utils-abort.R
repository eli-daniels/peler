# peler_abort ----

#' Signal a peler error
#'
#' Like [cli::cli_abort()], but the condition's `message` is the whole message
#' as one plain string. 'shiny' prints `message` as is: a cli message there is
#' a named vector, which shows as `[object Object]` and loses its bullets. The
#' console still gets the cli formatting, through `cnd_header()`.
#'
#' @param message A cli bullet vector, interpolated in `.envir`.
#' @param ... Fields passed to [rlang::abort()].
#' @param class Subclasses, added before `peler_error`.
#' @param call The call to report, by default the function that calls
#'   `peler_abort()`. Helpers pass on their own caller instead.
#' @param .envir Environment to interpolate `message` in.
#' @return Does not return.
#' @keywords internal
peler_abort <- function(message, ..., class = NULL, call = rlang::caller_env(), .envir = parent.frame()) {
  formatted <- cli::format_message(message, .envir = .envir)
  # The message is stored twice on purpose. `message` is the plain text, for 'shiny',
  # which reads that field directly. `formatted` keeps cli's colours, for the console.
  rlang::abort(
    cli::ansi_strip(formatted),
    ...,
    class = c(class, "peler_error"),
    call = call,
    formatted = formatted
  )
}

# rlang prints the header of an error from this method, so the console shows the
# coloured copy rather than the plain `message` kept for 'shiny'.
#' @exportS3Method rlang::cnd_header
cnd_header.peler_error <- function(cnd, ...) {
  cnd$formatted
}

#' Escape braces, so cli prints text as is
#' @noRd
cli_escape <- function(x) {
  gsub("}", "}}", gsub("{", "{{", x, fixed = TRUE), fixed = TRUE)
}

#' Bullets of one type, one per element of `x`, for a cli message
#'
#' `x` is often text already formatted with `cli::format_inline()`. It is
#' escaped because `peler_abort()` interpolates the message again, and a brace
#' in a value or a diagram's source would be read as code.
#' @noRd
bullets <- function(x, type) {
  structure(cli_escape(x), names = rep(type, length(x)))
}

# check_* ----

#' Argument checks, reporting the caller and the argument's name
#' @noRd
check_string <- function(x, allow_null = FALSE, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (allow_null && is.null(x)) return(invisible())
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    peler_abort("{.arg {arg}} must be a single string, not {.obj_type_friendly {x}}.", call = call)
  }
}

#' @noRd
check_number <- function(x, allow_null = FALSE, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (allow_null && is.null(x)) return(invisible())
  if (!is.numeric(x) || length(x) != 1L || is.na(x)) {
    peler_abort("{.arg {arg}} must be a single number, not {.obj_type_friendly {x}}.", call = call)
  }
  if (x <= 0) {
    peler_abort("{.arg {arg}} must be positive, not {x}.", call = call)
  }
}

#' @noRd
check_theme <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!is.null(x) && !inherits(x, "pele_theme")) {
    peler_abort(
      c(
        "{.arg {arg}} must be a theme or {.code NULL}, not {.obj_type_friendly {x}}.",
        i = "Make one with {.fn pele_theme}."
      ),
      call = call
    )
  }
}

#' @noRd
check_pele <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!inherits(x, "pele")) {
    peler_abort(
      c(
        "{.arg {arg}} must be a diagram, not {.obj_type_friendly {x}}.",
        i = "Make one with {.fn pele}."
      ),
      call = call
    )
  }
}
