module InstantCard
  MAJOR_VERSION = '1'
  MINOR_VERSION = '0'
  BUILD_VERSION = '23'
  REVISION = `git log --pretty=format:'%h' -n 1`
  VERSION = "v#{MAJOR_VERSION}.#{MINOR_VERSION}.#{BUILD_VERSION} (#{REVISION})"
end
