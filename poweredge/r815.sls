## CE-488: Resolve R815 Crashed
##
## Joshua Schmidlkofer <joshland@protonmail.com>
## Salt State written to install 
##
#8.1.0
{% if grains['os_family'] == 'RedHat' %}
legacy_cleanup:
  cmd.run:
    - name:   yum -y erase $(rpm -qa | grep srvadmin)
    - unless: rpm -q srvadmin-all|grep -v srvadmin-all-7

/etc/yum.repos.d/dell-omsa-repository.repo:
  file.managed:
    - source: salt://hardware/dell-r815.repo

dell_key_hardware:
  cmd.run:
    - name:   rpm --import http://linux.dell.com/repo/hardware/Linux_Repository_15.04.00/RPM-GPG-KEY-dell
    - unless: rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n' | grep c105b9de-4e0fd3a3
    - require:
      - file: /etc/yum.repos.d/dell-omsa-repository.repo 

dell_key_smbios:
  cmd.run:
    - name:   rpm --import http://linux.dell.com/repo/hardware/Linux_Repository_15.04.00/RPM-GPG-KEY-libsmbios
    - unless: rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n' | grep 5e3d7775-42d297af
    - require:
      - file: /etc/yum.repos.d/dell-omsa-repository.repo 


omsa_srvadmin:
  pkg.installed:
    - pkgs:
      - srvadmin-all
      - dell_ft_install
      - compat-libstdc++-33

r815_disable_cstates:
  cmd.run:
    - name: /opt/dell/srvadmin/sbin/omconfig chassis biossetup attribute=cpuc1e setting=disabled
    - unless: /opt/dell/srvadmin/sbin/omreport chassis biossetup|grep "Processor C1-E"|grep Disabled
  require:
    - pkg: omsa_srvadmin

r815_maxperformance:
  cmd.run:
    - name:   /opt/dell/srvadmin/sbin/omconfig chassis pwrmanagement config=profile profile=maxperformance
    - unless: /opt/dell/srvadmin/sbin/omreport chassis pwrmanagement config=profile|grep "Maximum.Performance"|grep 'Selected'
  require:
    - pkg: omsa_srvadmin

firmware_bootstrap:
  cmd.run:
    - name: yum -y install $(bootstrap_firmware)
  require:
    - pkg: omsa_srvadmin


{% endif %}
