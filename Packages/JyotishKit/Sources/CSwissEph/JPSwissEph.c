#include "JPSwissEph.h"
#include "swephexp.h"

#include <string.h>

int32_t jp_swe_calculate_ut(double julian_day_ut, int32_t body,
                            int32_t flags, jp_swe_position_result *result,
                            char *error, size_t error_capacity) {
  char swiss_error[AS_MAXCH] = {0};
  int32_t returned_flags = swe_calc_ut(julian_day_ut, body, flags,
                                       result->values, swiss_error);
  result->returned_flags = returned_flags;
  if (error != NULL && error_capacity > 0) {
    strncpy(error, swiss_error, error_capacity - 1);
    error[error_capacity - 1] = '\0';
  }
  return returned_flags;
}

int32_t jp_swe_houses_ut(double julian_day_ut, int32_t flags,
                         double latitude, double longitude,
                         int32_t house_system, jp_swe_houses_result *result) {
  return swe_houses_ex(julian_day_ut, flags, latitude, longitude,
                       house_system, result->cusps, result->angles);
}

double jp_swe_julian_day(int32_t year, int32_t month, int32_t day,
                         double utc_hour, int32_t gregorian) {
  return swe_julday(year, month, day, utc_hour, gregorian);
}

void jp_swe_set_ephemeris_path(const char *path) { swe_set_ephe_path((char *)path); }

void jp_swe_set_sidereal_mode(int32_t mode) { swe_set_sid_mode(mode, 0, 0); }

void jp_swe_close(void) { swe_close(); }
