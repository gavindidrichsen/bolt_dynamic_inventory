# 1. Extract bolt task logic into 'lib' directory to simplify rspect testing

Date: 2025-01-09

## Status

Accepted

## Context

A bolt task, like `tasks/resolve_reference.rb`, could include all necessary logic in the same file.  However, a better ruby practice is to extract the logic into the `lib` directory and then "share" this with the task by updating the task metadata. For more information on how to ensure bolt ships extra files and directories required for the operation of a task, see the [sharing task code](https://www.puppet.com/docs/bolt/latest/writing_tasks#sharing-task-code) documentation.

## Decision

Therefore, I decided to move all ruby logic beneath the `lib` directory and share the `lib` with the task on the target server.  For more information see the [appendix](#keypoints-for-sharing-code-with-tasks).

## Consequences

Now I can treat the code as simple ruby and, of course, test it with rspec.  In other words, I don't have to do anything special to test the task itself because the ruby code will be tested via the `spec` tests.

## Appendix

### Keypoints for sharing code with tasks

There are a few key points to achieving this:

* Push files and/or directories along with the task to the target server.  For example, my `orbstack_inventory/tasks/resolve_reference.json` metadata ensures the `lib` directory and the task are pushed to the target together::

  ```json
  {
    "description": "Resolve targets for Orbstack inventory",
    "input_method": "stdin",
    "files": ["orbstack_inventory/lib/"],
    "parameters": {}
  }
  ```

* Include the `lib` code in the task.  One way to do this is with a `require_relative` as follows:

  ```ruby
  require 'json'
  params = JSON.parse(STDIN.read)
  installdir = params['_installdir']
  ```
  
  then either `require_relative`:
  
  ```ruby
  require_relative File.join(installdir, 'orbstack_inventory', 'lib', 'orbstack_inventory.rb')
  ```
  
  or update the ruby `$LOAD_PATH` and use `require`:
  
  ```ruby
  $LOAD_PATH.unshift(File.join(installdir, 'orbstack_inventory', 'lib'))                                    # 
  require 'orbstack_inventory'
  ```
