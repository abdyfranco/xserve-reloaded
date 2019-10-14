#-------------------------------------------------------------------------
# Copyright (c) 2017 Apple Inc. All rights reserved.
#
# IMPORTANT NOTE: This file is licensed only for use on Apple-branded
# computers and is subject to the terms and conditions of the Apple Software
# License Agreement accompanying the package this file is a part of.
# You may not port this file to another platform without Apple's written consent.
#-------------------------------------------------------------------------

#-------------------------------------------------------------------------
class AppLockKnobSet < KnobSet
#-------------------------------------------------------------------------

  @@payload_type          = 'com.apple.app.lock'
  @@payload_subidentifier = 'app_lock'
  @@is_unique             = true
  @@payload_name          = 'Single App Mode'

  #-------------------------------------------------------------------------

  def self.old_table_name;  return 'app_lock_knob_sets';  end

  #-------------------------------------------------------------------------

  def localized_payload_display_name(short = false);  return I18n.t('single_app_mode_display_name'); end

  #-------------------------------------------------------------------------

  def modify_payload_hash(payload_hash)
    return { 'ios' => payload_hash }
  end # modify_payload_hash

  #-------------------------------------------------------------------------
#-------------------------------------------------------------------------
end # AppLockKnobSet
#-------------------------------------------------------------------------