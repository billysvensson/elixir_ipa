# Changelog

## v1.0.0
  * Elixir Interface for Pinout Attachments - elixir_ipa
    * Broke the API compatibility with the original project(s),
      changed name to reflect that.
  * New features
    * Using pin/devname/address instead of pid to address the correct server,
      all public API functions have been stripped of pid arguments.
    * Moved production implementations to prod-modules
    * Created mock-modules that can be used when testing on non-compliant
      hardware.
  * Bug fixes
    * Fixed issue where multiple callback messages for gpio interrupts of
      same condition could be sent in a row. Now callback messages is only
      sent when condition has changed.
    * Validating direction on GPIO read and writes.
