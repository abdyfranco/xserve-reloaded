/**
 * Copyright (c) 2010-2014, Apple Inc. All rights reserved. 
 * 
 * IMPORTANT NOTE: This file is licensed only for use on Apple-branded
 * computers and is subject to the terms and conditions of the Apple Software
 * License Agreement accompanying the package this file is a part of.
 * You may not port this file to another platform without Apple's written consent.
 * 
 * IMPORTANT NOTE: This file is licensed only for use with the Wiki Server feature
 * of the Apple Software and is subject to the terms and conditions of the Apple
 * Software License Agreement accompanying the package this file is part of.
 **/

DROP FUNCTION IF EXISTS work_schedule_next_run_times();
CREATE FUNCTION work_schedule_next_run_times()
  RETURNS SETOF work_schedule_expanded_recurrence
  AS $work_schedule_next_run_times$
    DECLARE
      sr      work_schedule_recurrence;
      ser     work_schedule_expanded_recurrence;
    BEGIN
      FOR sr IN SELECT uid, schedule_uid_fk, start_time, repeat_interval::interval FROM work_schedule_recurrence LOOP
        IF sr.repeat_interval IS NOT NULL AND sr.repeat_interval::interval <> '0 seconds'::interval THEN
          FOR ser IN SELECT sr.schedule_uid_fk, sr.uid, scheduled_time
                       FROM generate_series(sr.start_time, now()+sr.repeat_interval::interval, sr.repeat_interval::interval) AS scheduled_time
                      WHERE scheduled_time >= now()
          LOOP
            RETURN NEXT ser;
          END LOOP;
        ELSE
          IF sr.start_time BETWEEN now() AND now()+coalesce(sr.repeat_interval,'0 seconds'::interval) THEN
            ser.recurrence_uid_fk := sr.uid;
            ser.schedule_uid_fk := sr.schedule_uid_fk;
            ser.scheduled_time := sr.start_time;
            RETURN NEXT ser;
          END IF;
        END IF;
      END LOOP;
    END;
$work_schedule_next_run_times$ LANGUAGE plpgsql;