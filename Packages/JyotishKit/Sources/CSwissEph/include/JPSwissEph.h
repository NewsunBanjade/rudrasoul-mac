#ifndef JP_SWISS_EPH_H
#define JP_SWISS_EPH_H

#include <stddef.h>
#include <stdint.h>

typedef struct {
  double values[6];
  int32_t returned_flags;
} jp_swe_position_result;

typedef struct {
  double cusps[13];
  double angles[10];
} jp_swe_houses_result;

int32_t jp_swe_calculate_ut(double julian_day_ut, int32_t body,
                            int32_t flags, jp_swe_position_result *result,
                            char *error, size_t error_capacity);

int32_t jp_swe_houses_ut(double julian_day_ut, int32_t flags,
                         double latitude, double longitude,
                         int32_t house_system, jp_swe_houses_result *result);

double jp_swe_julian_day(int32_t year, int32_t month, int32_t day,
                         double utc_hour, int32_t gregorian);

/* Finds the next rising (rsmi = 1) or setting (rsmi = 2) of `body` after
   `julian_day_ut` for an observer at the given coordinates. Extra bits in
   `rsmi` follow Swiss Ephemeris (SE_BIT_HINDU_RISING = 896). Returns 0 on
   success, -2 when the body never rises or sets at that latitude, and a
   negative value on error. The event time is stored in `result_jd`. */
int32_t jp_swe_rise_trans(double julian_day_ut, int32_t body,
                          int32_t ephemeris_flags, int32_t rsmi,
                          double latitude, double longitude,
                          double *result_jd, char *error,
                          size_t error_capacity);

/* Returns the ayanamsa in degrees for the sidereal mode previously set with
   jp_swe_set_sidereal_mode. */
double jp_swe_get_ayanamsa_ut(double julian_day_ut);

void jp_swe_set_ephemeris_path(const char *path);
void jp_swe_set_sidereal_mode(int32_t mode);
void jp_swe_close(void);

#endif
