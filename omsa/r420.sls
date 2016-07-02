## CE-488: Resolve R815 Crashed
##
## Joshua Schmidlkofer <joshland@protonmail.com>
## Salt State written to install 
##
#8.3.0
##
##

##
## http://linux.dell.com/repo/hardware/DSU_16.04.00/
##
{% if grains['os_family'] == 'RedHat' %}
legacy_cleanup:
  cmd.run:
    - name:   yum -y erase $(rpm -qa | grep srvadmin)
    - unless: rpm -q srvadmin-base|grep srvadmin-base-8
      
    #- unless: rpm -q srvadmin-all|grep -v srvadmin-all-8

/etc/yum.repos.d/dell-system-update.repo:
  file.managed:
    - source: salt://hardware/{{ grains['os_family'] }}-{{ grains['osmajorrelease'] }}-dell-latest.repo

dell_key_hardware:
  cmd.run:
    - name:   rpm --import http://linux.dell.com/repo/hardware/latest/public.key
    - unless: rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n' | grep 23b66a9d-40912de4
    - require:
      - file: /etc/yum.repos.d/dell-system-update.repo

omsa_srvadmin:
  pkg.installed:
    - pkgs:
      - srvadmin-all
      - dell-system-update

update_firmware:
  cmd.run:
    - name: dsu -u -n
  require:
    - pkg: omsa_srvadmin

    
r420_enable_performance:
  cmd.run:
    - name: /opt/dell/srvadmin/sbin/omconfig chassis biossetup attribute=SysProfile setting=PerfOptimized
    - unless: /opt/dell/srvadmin/sbin/omreport chassis biossetup|grep "System Profile"|grep "Performance$"
  require:
    - pkg: omsa_srvadmin

r420_enable_sriov:
  cmd.run:
    - name: /opt/dell/srvadmin/sbin/omconfig chassis biossetup attribute=SriovGlobalEnable setting=Enabled
    - unless: /opt/dell/srvadmin/sbin/omreport chassis biossetup|grep "SR-IOV Global Enable"|grep Enable
  require:
    - pkg: omsa_srvadmin

r420_enable_ioatengine:
  cmd.run:
    - name: /opt/dell/srvadmin/sbin/omconfig chassis biossetup attribute=IoatEngine setting=Enabled
    - unless: /opt/dell/srvadmin/sbin/omreport chassis biossetup|grep "I/OAT DMA Engine"|grep Enable
  require:
    - pkg: omsa_srvadmin

r420_enable_oswatchdog:
  cmd.run:
    - name: /opt/dell/srvadmin/sbin/omconfig chassis biossetup attribute=OsWatchdogTimer setting=Enabled
    - unless: /opt/dell/srvadmin/sbin/omreport chassis biossetup|grep "OS Watchdog Timer"|grep Enable
  require:
    - pkg: omsa_srvadmin
{% endif %}
