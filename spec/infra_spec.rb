require 'dockerspec/serverspec'

describe 'Infrastructure CI Configuration' do
  describe docker_run('unifio/ci', env: {'TEST_MODE'=>'true'}) do

    # Verify /usr/local/bin additions
    @usr_local_binaries = %w(
      bundle
      dumb-init
      entrypoint.sh
      gem
      gosu
      packer
      packer-post-processor-vagrant-s3
      packer-provisioner-serverspec
      promote-atlas-artifact
      rake
      ruby
      terraform
    )

    @usr_local_binaries.each do |bin|
      describe file("/usr/local/bin/#{bin}") do
        it { should exist }
        it { should be_file }
        it { should be_executable.by('others') }
        it { should be_owned_by 'root' }
        its(:size) { should > 0 }
      end
    end

    # Verify binaries
    describe command('/usr/local/bin/terraform version') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /.*#{ENV['TERRAFORM_VERSION']}*/ }
    end

    describe command('/usr/local/bin/packer version') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /.*#{ENV['PACKER_VERSION']}*/ }
    end

    describe command('/usr/local/bin/rake --version') do
      its(:exit_status) { should eq 0 }
    end

    # Verify packages
    @apk_packages = %w(
      bash
      build-base
      ca-certificates
      curl
      curl-dev
      docker
      git
      glibc
      gnupg
      groff
      jq
      less
      mercurial
      openssl
      openssh
      python-dev
      ruby-dev
      tar
      unzip
      zip
      wget
    )

    @apk_packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed.by('apk') }
      end
    end

    @pip_packages = %w(
      awscli
      docker-compose
    )

    @pip_packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed.by('pip') }
      end
    end

    @gem_packages = %w(
      awesome_print
      consul_loader
      thor
    )

    @gem_packages.each do |pkg|
      describe command("bundle show | grep #{pkg}") do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match /.*#{pkg}*/ }
      end
    end

    describe command('bundle show | grep covalence') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /.*covalence (#{ENV['COVALENCE_VERSION']})*/ }
    end

  end
end
