# oracle-monitoring
Oracle Monitoring Package

This is the source code for my Oracle Monitoring package.

# Installation

1 - Connect in your Oracle RDBMS

2 - Creating package

SQL> @ ORCL_MONITORING.pkg.sql

SQL> @ ORCL_MONITORING.body.sql

3 - Testing 

SQL> select ORCL_MONITORING.get_hitratio_buffer_cache('metric') from dual;


# Troubleshooting 

In case of error checking your privileges to access dictionary views, I recommend creating this package on the DBA user role.



# How to use

	################################################################################
	#  Script      : Package Body ORCL_MONITORING
	#  Objective   : Monitoring Oracle Database
	#  Uses        : -
	#  Used By     : - oracle
	#  Call        : - exec ORCL_MONITORING.<function name>(<params>,...);
	#  Parameters  : 
	#				1) Type   			  (IN) [metric | status ]
	#				2) Threshold warning  (IN) <numeric>
	#				3) Threshold critical (IN) <numeric>
	# 				Returns
	#               - metric (OUT) --> real value
	#               - status (OUT) --> based on threshold value
	#               	 0: OK
	#               	 1: Warning
	#               	 2: Critical
	#               	-1: Error	
	#				
	#  Examples    :
	#  select ORCL_MONITORING.get_hitratio_buffer_cache('metric',94,90) from dual;
	#  select ORCL_MONITORING.get_hitratio_buffer_cache('metric') from dual;
	#  select ORCL_MONITORING.get_hitratio_buffer_cache('status') from dual;
	#
	#  Version  Date        Author              Comments
	#  -------  --------    ------------------  ------------------------------------
	#  1.0      20171019    Arnaldo Cavalcanti  Initial version
	#  1.1      20180329    Arnaldo Cavalcanti  Revision
	#
	################################################################################
	
  
# Where to use

You can use to check manually or implement in your monitoring tool. 
	
  
# Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
