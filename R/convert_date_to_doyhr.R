#' Convert a date to a day of year (1-366) with decimal hours
#' 
#' Inspired by / copied from LakeMetabolizer date2doy
#' 
#' @param date A datetime object as POSIXct or POSIXt
#' @return Numeric value expressing the date as the number of days, with decimal
#'   hours, since 00:00 of December 31 of the preceding year (i.e., January 1st
#'   at 00:01 is ~1.01)
#' @examples 
#' streamMetabolizer:::convert_date_to_doyhr(as.POSIXct("2015-02-03 12:01:00 UTC"))
#' @export
convert_date_to_doyhr <- function(date) {
  
  # plan for deprecation is to make this internal (stop exporting) - it's used
  # by mm_model_by_ply and convert_UTC_to_solartime, but external use should be
  # limited
  called_as_internal <- all(c(':::','streamMetabolizer') %in% as.character(sys.call()[[1]])) ||
    any(sapply(sys.calls()[-sys.nframe()], function(sc) if(class(sc[[1]]) == 'name') tail(as.character(sc[[1]]), 1) else NA) %in% 
          ls(envir = asNamespace("streamMetabolizer")))
  if(!called_as_internal) {
    .Deprecated()
    warning("submit a GitHub issue if you want convert_date_to_doyhr() to stick around", call.=FALSE)
  }
  
  year <- as.POSIXct(format(v(date), "%Y-01-01 00:00:00"), tz=lubridate::tz(v(date)))
  out <- as.numeric(v(date) - year, units="days") + 1 # days_since_dec31
  if(is.unitted(date)) out <- u(out, get_units(date))
  out
}

#' Convert a a day of year (1-366) with decimal hours to a date
#' 
#' @param doyhr Numeric value expressing the date as the number of days, with
#'   decimal hours, since 00:00 of December 31 of the preceding year
#' @param year Numeric 4-digit year
#' @param tz The time zone to pass to as.POSIXct()
#' @param origin The origin to pass to as.POSIXct()
#' @param ... Other arguments to pass to as.POSIXct()
#' @return A datetime object as POSIXct
#' @examples 
#' streamMetabolizer:::convert_doyhr_to_date(34.500695, 2015)
#' @export
convert_doyhr_to_date <- function(doyhr, year, tz="UTC", origin=as.POSIXct("1970-01-01 00:00:00",tz="UTC"), ...) {
  
  # plan for deprecation is to make this internal (stop exporting) - it's used 
  # to test convert_date_to_doyhr, but external use should be limited
  called_as_internal <- all(c(':::','streamMetabolizer') %in% as.character(sys.call()[[1]])) ||
    any(sapply(sys.calls()[-sys.nframe()], function(sc) if(class(sc[[1]]) == 'name') tail(as.character(sc[[1]]), 1) else NA) %in% 
          ls(envir = asNamespace("streamMetabolizer")))
  if(!called_as_internal) {
    .Deprecated()
    warning("submit a GitHub issue if you want convert_doyhr_to_date() to stick around", call.=FALSE)
  }
  
  secs_since_jan1 <- (v(doyhr)-1)*24*60*60
  out <- as.POSIXct(sprintf("%d-01-01 00:00:00",v(year)), format="%Y-%m-%d %H:%M:%S", tz=tz, origin=origin, ...) + secs_since_jan1
  if(is.unitted(doyhr)) out <- u(out, get_units(doyhr))
  out
}
