#-------------------------------------------------------------------------
# Copyright (c) 2013 Apple Inc. All Rights Reserved.
#
# IMPORTANT NOTE: This file is licensed only for use on Apple-branded
# computers and is subject to the terms and conditions of the Apple Software
# License Agreement accompanying the package this file is a part of.
# You may not port this file to another platform without Apple's written consent.
#-------------------------------------------------------------------------

class CreateLdapKnobSets < ActiveRecord::Migration

  include KnobSetBase

  #-------------------------------------------------------------------------

  def self.up
    create_table :ldap_knob_sets do |t|
      KnobSetBase.add_base_table_properties(t)

      t.string  :LDAPAccountDescription
      t.string  :LDAPAccountHostName
      t.boolean :LDAPAccountUseSSL
      t.string  :LDAPAccountUserName
      t.string  :LDAPAccountPassword
      t.text    :LDAPSearchSettings
    end
  end

  #-------------------------------------------------------------------------

end