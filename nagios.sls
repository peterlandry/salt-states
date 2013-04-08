{% if 'nagios' in grains.get('roles', []) %}
{% set nagios = pillar.get('nagios', {}) %}
php5-fpm:
    pkg:
        - installed
    service:
        - running
        - watch:
            - file: /etc/php5/fpm/pool.d/www.conf

/etc/php5/fpm/pool.d/www.conf:
    file.managed:
        - source: salt://etc/php5/fpm/pool.d/www.conf
        - require:
            - pkg.installed: php5-fpm

fcgiwrap:
    pkg.installed

nagios-nrpe-plugin:
    pkg.installed

libdbi-perl:
    pkg.installed

libdbd-mysql-perl:
    pkg.installed


/etc/nagios3/htpasswd.users:
    file.managed:
        - source: salt://etc/nagios3/htpasswd.users
        - template: jinja
        - require:
            - pkg.installed: nagios3

/etc/nagios3/cgi.cfg:
    file.managed:
        - source: salt://etc/nagios3/cgi.cfg
        - template: jinja
        - require:
            - pkg.installed: nagios3

/var/spool/nagios:
    file.directory:
        - user: nagios
        - group: www-data
        - mode: 770

/var/spool/nagios/graphios:
    file.directory:
        - user: nagios
        - group: www-data
        - mode: 770
        - require:
            - file: /var/spool/nagios

{% set nagios_config_files = [
    '/etc/nagios3/conf.d/contacts.cfg',
    '/etc/nagios3/conf.d/contactgroups.cfg',
    '/etc/nagios3/conf.d/commands.cfg',
    '/etc/nagios3/conf.d/timeperiods.cfg',
    '/etc/nagios3/conf.d/hosts.cfg',
    '/etc/nagios3/conf.d/hostgroups.cfg',
    '/etc/nagios3/conf.d/services.cfg',
    ]
%}

/etc/nagios3/nagios.cfg:
    file.managed:
        - source: salt://etc/nagios3/nagios.cfg
        - template: jinja
        - context:
            nagios_config_files: {{nagios_config_files}}
        - require:
            - pkg.installed: nagios3

nagios3:
    pkg:
        - installed
        - require:
            - pkg.installed: php5-fpm
            - pkg.installed: fcgiwrap
            - pkg.installed: nagios-nrpe-plugin
            #- cmd.run: run_build_check_mysql_health
            #- file: /usr/local/bin/check_redis.pl
    service:
        - running
        - require:
            - file: /var/spool/nagios/graphios
        - watch:
            - file: /etc/nagios3/htpasswd.users
            - file: /etc/nagios3/nagios.cfg
            - file: /etc/nagios3/cgi.cfg
            {% for cf in nagios_config_files %}
            - file: {{cf}}
            {% endfor %}

{% for cf in nagios_config_files %}
{{ cf }}:
    file.managed:
        - source: salt:/{{ cf }}
        - template: jinja
        - context:
            nagios_config_files: {{nagios_config_files}}
        - require:
            - pkg.installed: nagios3
{% endfor %}

/var/lib/nagios3/rw:
    file.directory:
        - user: nagios
        - group: www-data
        - mode: 770

#python-cloudlb:
#    pip.installed:
#        - editable: git+git://github.com/rackspace/python-cloudlb.git@383d8f74806a9e27f5721dc14320c0c45e1b59c3#egg=python-cloudlb

nagiosplugin:
    pip.installed:
        - editable: hg+https://bitbucket.org/gocept/nagiosplugin@de87901#egg=nagiosplugin

python-statsd:
    pip.installed

# Uninstall previous files, or files installed by Ubuntu package
{% for cf in nagios.get('config_files_absent', []) %}
{{cf}}:
    file.absent
{% endfor %}

{% endif %} {# role nagios #}
