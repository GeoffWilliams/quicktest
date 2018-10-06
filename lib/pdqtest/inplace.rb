require 'pdqtest/puppet'
require 'open3'
module PDQTest
  module Inplace
    INPLACE_IMAGE = "__INPLACE__"
    @@enable = false

    def self.set_enable(enable)
      if enable
        $logger.warn <<~END
          PDQTest run with --inplace --inplace-enable will run Puppet on 
          *this* computer! 
  
          You have 5 seconds to abort, press ctrl+c now
        END
        sleep(5)
      end
      @@enable = enable
    end

    def self._exec_real(container, real_c)
      res = {}

      res[:OUT]    = []
      res[:ERR]    = []
      res[:STATUS] = 0
      $logger.debug("exec_real: running inplace command: #{real_c}")
      if @@enable
        env = ENV.reject { |e|
          [
              "BUNDLER_ORIG_BUNDLER_ORIG_MANPATH",
              "BUNDLER_ORIG_BUNDLER_VERSION",
              "BUNDLER_ORIG_BUNDLE_BIN_PATH",
              "BUNDLER_ORIG_BUNDLE_GEMFILE",
              "BUNDLER_ORIG_GEM_HOME",
              "BUNDLER_ORIG_GEM_PATH",
              "BUNDLER_ORIG_MANPATH",
              "BUNDLER_ORIG_PATH",
              "BUNDLER_ORIG_RB_USER_INSTALL",
              "BUNDLER_ORIG_RUBYLIB",
              "BUNDLER_ORIG_RUBYOPT",
              "BUNDLER_VERSION",
              "BUNDLE_BIN_PATH",
              "BUNDLE_GEMFILE",
              "GEM_HOME",
              "GEM_PATH",
              "MANPATH",
              "PROMPT",
              "RUBYLIB",
              "RUBYOPT",

              # more random crap
              "rvm_bin_path",
              "IRBRC",
              "MY_RUBY_HOME",
              "rvm_path",
              "rvm_prefix",
              "RUBY_VERSION"
          ].include? e
        }

        env["PATH"] = "/usr/local/bats/bin:/usr/sbin:/sbin:/usr/bin:/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/pdk/bin"
        env["LC_ALL"]="C"
        env["LANG"]="C"
        $logger.debug("running command with ENV: #{env}")
        #stdout, stderr, status = Open3.capture3(env, *real_c)

        Bundler.with_clean_env do
          system(env, *real_c)
          res[:STATUS] = 0
          res[:OUT] = ["grr"]#stdout.split("\n")
          res[:ERR] =["arg"] #stderr.split("\n")
        end
        #res[:STATUS] = status.exitstatus
      else
        $logger.info "didn't run command, reason: DISABLED"
      end
      $logger.debug("...result: #{res[:STATUS]}")

      res
    end

    def self.id
      INPLACE_IMAGE
    end

    def self.new_container(image_name, privileged)
      FileUtils.rm_rf Docker.test_dir if Dir.exist? Docker.test_dir

      FileUtils.cp_r(File.join(Dir.pwd, "."), Docker.test_dir)
    end

    def self.cleanup_container(container)
      FileUtils.rm_rf Docker.test_dir
    end
  end
end