# @summary A plan created with bolt plan new.
# @param targets The targets to run on.
plan usage::sayhello (
  TargetSpec $targets = "localhost"
) {
  apply_prep($targets)
  apply($targets) {
    notify { "Hello from usage::sayhello: [${facts['role']}]": }
    file { '/tmp/hello':
      ensure  => file,
      content => "Hello from usage::sayhello: [${facts['role']}]",
    }
  }
}
