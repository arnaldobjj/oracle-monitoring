CREATE OR REPLACE PACKAGE BODY "ORCL_MONITORING" AS
/*
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
*/

-- Global variables
OWNER_APP					varchar2(10) := 'IFSAPP'; 

-- Constants recommendations for warning/ critical values
-- Value "-1" means ignore threshold and return zero "0"
-- Value "0" means alarms based on count
DB_STATUS_W					number := 1;
DB_STATUS_C					number := 1;
HITRATIO_BUFFER_CACHE_W  	number := 94;
HITRATIO_BUFFER_CACHE_C	 	number := 90;
HITRATIO_LIBRARY_CACHE_W 	number := 98;
HITRATIO_LIBRARY_CACHE_C 	number := 92;
HITRATIO_ROW_CACHE_W	 	number := 90;
HITRATIO_ROW_CACHE_C	 	number := 80;
HITRATIO_PGA_W	 			number := 90;
HITRATIO_PGA_C	 			number := 80;
HITRATIO_SOFT_PARSE_W  		number := 94;
HITRATIO_SOFT_PARSE_C	 	number := 90;
HITRATIO_REDO_ALLOCATION_W	number := 94;
HITRATIO_REDO_ALLOCATION_C	number := 90;
HITRATIO_MEMORY_SORTS_W		number := 94;
HITRATIO_MEMORY_SORTS_C		number := 90;
HITRATIO_WITHOUT_PARSE_W	number := 20;
HITRATIO_WITHOUT_PARSE_C	number := 10;
HITRATIO_PROCESS_LIMIT_W	number := 80;
HITRATIO_PROCESS_LIMIT_C	number := 70;
HITRATIO_SESSION_LIMIT_W	number := 80;
HITRATIO_SESSION_LIMIT_C	number := 70;
CURRENT_LOGONS_W			number := 200;
CURRENT_LOGONS_C			number := 250;
ACTIVE_SESSIONS_W			number := 30;
ACTIVE_SESSIONS_C		    number := 50;
CURRENT_OPEN_CURSORS_W		number := 1500;
CURRENT_OPEN_CURSORS_C      number := 2000;
DATABASE_WAIT_TIME_W		number := 70;
DATABASE_WAIT_TIME_C		number := 80;
SHARED_POOL_FREE_W			number := 5;
SHARED_POOL_FREE_C			number := 1;
DATABASE_CPU_TIME_W			number := -1;
DATABASE_CPU_TIME_C			number := -1;
TEMP_SPACE_USED_W			number := 10000000000;
TEMP_SPACE_USED_C			number := 15000000000;
MBPS_W 						number := -1;
MBPS_C 						number := -1;
IOPS_W 						number := -1;
IOPS_C 						number := -1;
SCAN_ERROR_DB_W				number := 0;
SCAN_ERROR_DB_C				number := 0;
REDO_LOG_SWITCH_W			number := 15;
REDO_LOG_SWITCH_C			number := 10;
LOCKED_OBJECTS_W            number := 0;
LOCKED_OBJECTS_C            number := 0;
INVALID_OBJECTS_W			number := 0;
INVALID_OBJECTS_C			number := 0;
STATISTICS_W				number := 0;
STATISTICS_C				number := 0;
RESTORE_POINT_ACTIVE_W		number := 0;
RESTORE_POINT_ACTIVE_C		number := 0;
MATERIALIZED_VIEW_W			number := 0;
MATERIALIZED_VIEW_C			number := 0;
INDEX_UNUSABLE_W			number := 0;
INDEX_UNUSABLE_C			number := 0;
SECURITY_DBA_W				number := 0;
SECURITY_DBA_C				number := 0;
SECURITY_ANY_W				number := 0;
SECURITY_ANY_C				number := 0;
SECURITY_RISK_TABLES_W		number := 0;
SECURITY_RISK_TABLES_C		number := 0;
DISABLED_CONSTRAINTS_W		number := 0;
DISABLED_CONSTRAINTS_C		number := 0;
NUMBER_ARCHIVES_W			number := 24;
NUMBER_ARCHIVES_C			number := 30;
SIZE_ARCHIVES_W				number := 2500;
SIZE_ARCHIVES_C				number := 3000;
STANDBY_CHECK_ERROR_W		number := 0;
STANDBY_CHECK_ERROR_C		number := 0;
STANDBY_CHECK_LAG_W			number := 3600;
STANDBY_CHECK_LAG_C			number := 7200;
DATABASE_ALLOCATED_W		number := 500;
DATABASE_ALLOCATED_C		number := 1000;
DATABASE_USED_W				number := -1;
DATABASE_USED_C				number := -1;
BACKUP_TIME_W				number := 2;
BACKUP_TIME_C				number := 4;
BACKUP_STATUS_W				number := 0;
BACKUP_STATUS_C				number := 0;
BACKUP_FREQUENCY_W			number := 2;
BACKUP_FREQUENCY_C			number := 2;
TBS_PCTUSED_W				number := 80;
TBS_PCTUSED_C				number := 90;
FILE_IO_W					number := -1;
FILE_IO_C					number := -1;
TOP5_EVENTS_W				number := -1;
TOP5_EVENTS_C				number := -1;
SGA_BUFFER_CACHE_W			number := -1;
SGA_BUFFER_CACHE_C			number := -1;
SGA_FIXED_W					number := -1;
SGA_FIXED_C					number := -1;
SGA_JAVA_POOL_W				number := -1;
SGA_JAVA_POOL_C				number := -1;
SGA_LARGE_POOL_W			number := -1;
SGA_LARGE_POOL_C			number := -1;
SGA_LOG_BUFFER_W			number := -1;
SGA_LOG_BUFFER_C			number := -1;
SGA_SHARED_POOL_W			number := -1;
SGA_SHARED_POOL_C			number := -1;



	/*==============================================================*/
	/* Database Status												*/
	/*==============================================================*/
	function get_db_status(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0; 		
		if p_warning is null then
			v_warning := DB_STATUS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := DB_STATUS_C;
		else
			v_critical := p_critical;
		end if;			
		
		v_str:= 'select ' || chr(10);
		v_str:= v_str || '	case when 	(open_mode=' ||chr(39) || 'READ WRITE' ||chr(39) || ' and database_role=' ||chr(39) || 'PRIMARY' ||chr(39) || ') or ' || chr(10);
		v_str:= v_str || '				(open_mode=' ||chr(39) || 'MOUNTED' ||chr(39) || ' and database_role=' ||chr(39) || 'PHYSICAL STANDBY' ||chr(39) || ') then 0 ' || chr(10);
		v_str:= v_str || ' else 2 ' || chr(10);
		v_str:= v_str || ' end x ' || chr(10);
		v_str:= v_str || 'from (select open_mode, database_role  from v$database)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_db_status;
	

	
	/*==============================================================*/
	/* HitRatio Buffer Cache										*/
	/*==============================================================*/
	function get_hitratio_buffer_cache(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0; 		
		if p_warning is null then
			v_warning := HITRATIO_BUFFER_CACHE_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := HITRATIO_BUFFER_CACHE_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Buffer Cache Hit Ratio' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_hitratio_buffer_cache;

	
	
	/*==============================================================*/
	/* HitRatio Library Cache										*/
	/*==============================================================*/
	function get_hitratio_library_cache(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := HITRATIO_LIBRARY_CACHE_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := HITRATIO_LIBRARY_CACHE_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Library Cache Hit Ratio' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_hitratio_library_cache;


	
	/*==============================================================*/
	/* HitRatio Row Cache											*/
	/*==============================================================*/
	function get_hitratio_row_cache(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := HITRATIO_ROW_CACHE_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := HITRATIO_ROW_CACHE_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Row Cache Hit Ratio' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_hitratio_row_cache;


	
	/*==============================================================*/
	/* HitRatio PGA													*/
	/*==============================================================*/
	function get_hitratio_pga(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := HITRATIO_PGA_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := HITRATIO_PGA_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'PGA Cache Hit %' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_hitratio_pga;

	

	/*==============================================================*/
	/* HitRatio Soft Parse											*/
	/*==============================================================*/
	function get_hitratio_soft_parse(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := HITRATIO_SOFT_PARSE_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := HITRATIO_SOFT_PARSE_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Soft Parse Ratio' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_hitratio_soft_parse;


	
	/*==============================================================*/
	/* HitRatio Redo Allocation										*/
	/*==============================================================*/
	function get_hitratio_redo_allocation(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := HITRATIO_REDO_ALLOCATION_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := HITRATIO_REDO_ALLOCATION_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Redo Allocation Hit Ratio' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;

		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_hitratio_redo_allocation;

	

	/*==============================================================*/
	/* HitRatio Memory Sorts 										*/
	/*==============================================================*/
	function get_hitratio_memory_sorts(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := HITRATIO_MEMORY_SORTS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := HITRATIO_MEMORY_SORTS_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Memory Sorts Ratio' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
	
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_hitratio_memory_sorts;
	

	
	/*==============================================================*/
	/* HitRatio Execute Without Parse 								*/
	/*==============================================================*/
	function get_hitratio_without_parse(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := HITRATIO_WITHOUT_PARSE_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := HITRATIO_WITHOUT_PARSE_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Execute Without Parse Ratio' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_hitratio_without_parse;

	
	
	/*==============================================================*/
	/* Process Limit % 												*/
	/*==============================================================*/
	function get_hitratio_process_limit(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := HITRATIO_PROCESS_LIMIT_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := HITRATIO_PROCESS_LIMIT_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Process Limit %' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_hitratio_process_limit;
	


	/*==============================================================*/
	/* Session Limit % 												*/
	/*==============================================================*/
	function get_hitratio_session_limit(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := HITRATIO_SESSION_LIMIT_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := HITRATIO_SESSION_LIMIT_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Session Limit %' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_hitratio_session_limit;


	
	/*==============================================================*/
	/* Current Logons Count											*/
	/*==============================================================*/
	function get_current_logons(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := CURRENT_LOGONS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := CURRENT_LOGONS_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Current Logons Count' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_current_logons;

	
	/*==============================================================*/
	/* Active Sessions												*/
	/*==============================================================*/
	function get_active_sessions(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := ACTIVE_SESSIONS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := ACTIVE_SESSIONS_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:= 'select count(1) x from v$session where status= ' || chr(39) ||'ACTIVE' || chr(39) || ' and username is not null';	

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_active_sessions;
	
	

	/*==============================================================*/
	/* Current Open Cursors Count									*/
	/*==============================================================*/
	function get_current_open_cursors(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := CURRENT_OPEN_CURSORS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := CURRENT_OPEN_CURSORS_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Current Open Cursors Count' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_current_open_cursors;

	

	/*==============================================================*/
	/* Database Wait Time Ratio										*/
	/*==============================================================*/
	function get_database_wait_time(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := DATABASE_WAIT_TIME_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := DATABASE_WAIT_TIME_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Database Wait Time Ratio' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_database_wait_time;
	

	
	/*==============================================================*/
	/* Shared Pool Free %											*/
	/*==============================================================*/
	function get_shared_pool_free(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SHARED_POOL_FREE_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SHARED_POOL_FREE_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Shared Pool Free %' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;		
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_shared_pool_free;
	

	/*==============================================================*/
	/* Database CPU Time Ratio										*/
	/*==============================================================*/
	function get_database_cpu_time(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := DATABASE_CPU_TIME_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := DATABASE_CPU_TIME_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'Database CPU Time Ratio' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_database_cpu_time;
	

	
	/*==============================================================*/
	/* Temp Space Used												*/
	/*==============================================================*/
	function get_temp_space_used(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := TEMP_SPACE_USED_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := TEMP_SPACE_USED_C;
		else
			v_critical := p_critical;
		end if;
		
		
		v_str:= 'select round(value,2)/1024/1024 x from v$sysmetric where metric_name = ' || chr(39) || 'Temp Space Used' || chr(39) || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';

		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_temp_space_used;

	

	/*==============================================================*/
	/* MBPS															*/
	/*==============================================================*/	
	function get_mbps(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := MBPS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := MBPS_C;
		else
			v_critical := p_critical;
		end if;
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'I/O Megabytes per Second' || chr(39) || chr(10);
		v_str:= v_str || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';
		
		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
	
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_mbps;
	

	
	/*==============================================================*/
	/* IOPS															*/
	/*==============================================================*/	
	function get_iops(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := IOPS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := IOPS_C;
		else
			v_critical := p_critical;
		end if;
		
		v_str:= 'select round(value,2) x from v$sysmetric where metric_name = ' || chr(39) || 'I/O Requests per Second' || chr(39) || chr(10);
		v_str:= v_str || ' and intsize_csec = (select max(intsize_csec) from gv$sysmetric)';
		
		execute immediate v_str into v_return;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
	
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_iops;

	

	/*==============================================================*/
	/* Scan Errors Database	(alert log file)						*/
	/*==============================================================*/
	function get_scan_error_db(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SCAN_ERROR_DB_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SCAN_ERROR_DB_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:='select nvl(count(1),0) x from x$dbgalertext where originating_timestamp > (sysdate-5/24) and message_text like ' || chr(39) || '%ORA-%' || chr(39);

		execute immediate v_str into v_return;
		
		-- check if value is null/ avoid misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;


		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_scan_error_db;



	/*==============================================================*/
	/* Redo Log Switch												*/
	/*==============================================================*/
	function get_redo_log_switch(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := REDO_LOG_SWITCH_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := REDO_LOG_SWITCH_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:= 'select trunc(avg(((a.first_time-b.first_time)*24)*60)) x from v$log_history a, v$log_history b where a.recid = b.recid+1 and trunc(b.first_time) = trunc(SYSDATE)';		

		execute immediate v_str into v_return;
		
		-- check if value is null/ avoid misunderstand value
		if v_return is null then
			v_return:= v_warning*4;
		end if;		
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return < v_critical then 
					v_return:=2;
				elsif v_return < v_warning and v_return > v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_redo_log_switch;

	
	/*==============================================================*/
	/* Locked Objects 												*/
	/*==============================================================*/	
	function get_locked_objects(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := LOCKED_OBJECTS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := LOCKED_OBJECTS_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:='select count(1) x from gv$locked_object, sys.dba_objects where gv$locked_object.object_id=sys.dba_objects.object_id';

		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_locked_objects;	
	
	
	/*==============================================================*/
	/* Invalid Objects												*/
	/*==============================================================*/
	function get_invalid_objects(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := INVALID_OBJECTS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := INVALID_OBJECTS_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:='select count(1) x from dba_invalid_objects where object_type <> ' || chr(39) || 'MATERIALIZED VIEW' || chr(39);

		execute immediate v_str into v_return;
		
		-- check if value is null/ avoid misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_invalid_objects;

	
	
	/*==============================================================*/
	/* Statistics													*/
	/*==============================================================*/
	function get_statistics(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := STATISTICS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := STATISTICS_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:='select count(1) x from (select job_status, JOB_START_TIME FROM dba_autotask_job_history ' || chr(10);
		v_str:=v_str || 'WHERE client_name=' || chr(39) || 'auto optimizer stats collection' || chr(39) || ' and job_status<>' || chr(39) || 'SUCCEEDED' || chr(39);
		v_str:=v_str || ' and JOB_START_TIME>(SYSDATE - 1))';

		execute immediate v_str into v_return;
		
		-- check if value is null/ avoid misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;		

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_statistics;	

	

	/*==============================================================*/
	/* Restore Point Active											*/
	/*==============================================================*/
	function get_restore_point_active(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := RESTORE_POINT_ACTIVE_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := RESTORE_POINT_ACTIVE_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:='select count(1) amount from gv$restore_point';

		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_restore_point_active;		

	

	/*==============================================================*/
	/* Materialized View											*/
	/*==============================================================*/
	function get_materialized_view(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := MATERIALIZED_VIEW_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := MATERIALIZED_VIEW_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:='select count(1) x from dba_mviews where owner=' || chr(39) || OWNER_APP || chr(39) || ' and last_refresh_date < (sysdate - 1)';

		execute immediate v_str into v_return;
		
		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_materialized_view;	
	

	
	/*==============================================================*/
	/* Index Unusable												*/
	/*==============================================================*/
	function get_index_unusable(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := INDEX_UNUSABLE_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := INDEX_UNUSABLE_C;
		else
			v_critical := p_critical;
		end if;		
		
		v_str:='select count(1) x from dba_indexes where owner=' || chr(39) || OWNER_APP || chr(39) || ' and status = ' || chr(39) || 'UNUSABLE' || chr(39);

		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_index_unusable;	



	/*==============================================================*/
	/* Security DBA													*/
	/*==============================================================*/
	function get_security_dba(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SECURITY_DBA_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SECURITY_DBA_C;
		else
			v_critical := p_critical;
		end if;				
		
		v_str:='select count(1) x from dba_role_privs where granted_role=' || chr(39) || 'DBA' || chr(39) || chr(10);
		v_str:=v_str || ' and grantee not in ('|| chr(39) || 'SYS' || chr(39) || ',' || chr(39) || 'SYSTEM' || chr(39) || ',' || chr(39) || 'SYSMAN' || chr(39) || ') '|| chr(10);
		v_str:=v_str || ' and grantee not in (SELECT username FROM dba_users WHERE account_status <> '|| chr(39) || 'OPEN'|| chr(39) || ')';		

		execute immediate v_str into v_return;

		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_security_dba;		
	

	
	/*==============================================================*/
	/* Security ANY													*/
	/*==============================================================*/
	function get_security_any(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SECURITY_ANY_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SECURITY_ANY_C;
		else
			v_critical := p_critical;
		end if;				
		
		v_str:='select count(*) x from dba_sys_privs where privilege like '|| chr(39) || '%ANY%' || chr(39) || ' and grantee not in ' || chr(10);
		v_str:=v_str || '('|| chr(39) || 'DBA'|| chr(39) || ',' || chr(39) || 'DBSNMP'|| chr(39) || ','|| chr(39) || 'SYS'|| chr(39) || ',' || chr(39) || 'SYSTEM'|| chr(39) || ','|| chr(10); 
		v_str:=v_str || chr(39) || 'SYSMAN'|| chr(39) || ',' || chr(39) || 'AQ_ADMINISTRATOR_ROLE'|| chr(39) || ',' || chr(39) || 'OLAP_DBA'|| chr(39) || ',' || chr(10);
		v_str:=v_str || chr(39) || 'DATAPUMP_IMP_FULL_DATABASE'|| chr(39) || ',' || chr(39) || 'IMP_FULL_DATABASE'|| chr(39) || ',' || chr(39) || 'EXP_FULL_DATABASE'|| chr(39) || ','|| chr(10);
		v_str:=v_str || chr(39) || 'SCHEDULER_ADMIN'|| chr(39) || ','|| chr(39) || 'OEM_MONITOR'|| chr(39) || ',' || chr(39) || 'ORCL_MONITOR'|| chr(39) || ',' || chr(10);
		v_str:=v_str || chr(39) || 'OWB$CLIENT'|| chr(39) || ',' || chr(39) || 'RECOVERY_CATALOG_OWNER'|| chr(39) || ','|| chr(39) || 'EM_EXPRESS_ALL'|| chr(39) || ','|| chr(39) || OWNER_APP || chr(39) || ')' || chr(10);
		v_str:=v_str || ' and grantee not in (SELECT username FROM dba_users WHERE account_status<>' || chr(39) || 'OPEN' || chr(39) || ') 	and grantee || privilege not in ( ' || chr(10); 
		v_str:=v_str || ' select grantee || privilege ' || chr(10);
		v_str:=v_str || ' from dba_sys_privs ' || chr(10);
		v_str:=v_str || ' where (grantee='|| chr(39) ||'JAVADEBUGPRIV'||chr(39)  || ' and PRIVILEGE=' || chr(39) || 'DEBUG ANY PROCEDURE'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'OUTLN'          || chr(39) || ' and PRIVILEGE=' || chr(39) || 'EXECUTE ANY PROCEDURE'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'FND_DEVELOPER'  || chr(39) || ' and PRIVILEGE=' || chr(39) || 'DEBUG ANY PROCEDURE' || chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'FND_DEVELOPER'  || chr(39) || ' and PRIVILEGE=' || chr(39) || 'CREATE ANY PROCEDURE'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'JAVADEBUGPRIV'  || chr(39) || ' and PRIVILEGE=' || chr(39) || 'DEBUG ANY PROCEDURE'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'FND_RUNTIME'    || chr(39) || ' and PRIVILEGE=' || chr(39) || 'MERGE ANY VIEW'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'FND_ADMIN'      || chr(39) || ' and PRIVILEGE=' || chr(39) || 'MANAGE ANY QUEUE'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'AUDIT_ADMIN'    || chr(39) || ' and PRIVILEGE=' || chr(39) || 'AUDIT ANY'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'FND_WEBCONFIG'  || chr(39) || ' and PRIVILEGE=' || chr(39) || 'MERGE ANY VIEW'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'IFSSYS'         || chr(39) || ' and PRIVILEGE=' || chr(39) || 'MANAGE ANY QUEUE'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'IFSSYS'         || chr(39) || ' and PRIVILEGE=' || chr(39) || 'DEQUEUE ANY QUEUE'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'IFSSYS'         || chr(39) || ' and PRIVILEGE=' || chr(39) || 'MERGE ANY VIEW'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'IFSSYS'         || chr(39) || ' and PRIVILEGE=' || chr(39) || 'DEBUG ANY PROCEDURE'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'IFSSYS'         || chr(39) || ' and PRIVILEGE=' || chr(39) || 'ENQUEUE ANY QUEUE'|| chr(39) || ') ' || chr(10);
		v_str:=v_str || ' or (grantee='|| chr(39) || 'IFSINFO'        || chr(39) || ' and PRIVILEGE=' || chr(39) || 'MERGE ANY VIEW'|| chr(39) || '))';
		
		execute immediate v_str into v_return;

		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;		
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_security_any;		

	

	/*==============================================================*/
	/* Security Risk Tables											*/
	/*==============================================================*/
	function get_security_risk_tables(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SECURITY_RISK_TABLES_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SECURITY_RISK_TABLES_C;
		else
			v_critical := p_critical;
		end if;				
		
		v_str:='select count(1) x from dba_tab_privs where table_name in (' || chr(10); 		
		v_str:=v_str || 'select table_name from dict where table_name like ' || chr(39) || 'V$%' || chr(39) || chr(10);
		v_str:=v_str || ' or table_name like ' || chr(39) || 'GV$%'|| chr(39) || chr(10);
		v_str:=v_str || ' or table_name like ' || chr(39) || 'X$%' || chr(39) || chr(10);
		v_str:=v_str || ' or table_name in ('|| chr(39) || 'LINK$'|| chr(39) || ',' || chr(39) || 'SOURCE$'|| chr(39) || ',' || chr(39) || 'AUD$' || chr(39) || ',' || chr(10); 
		v_str:=v_str || chr(39) || 'STATS$SQL_SUMMARY'|| chr(39) || ','|| chr(39) || 'STATS$SQLTEXT'|| chr(39) || ','|| chr(39) || 'DBA_DB_LINKS'|| chr(39) || '))' || chr (10);
		-- v_str:=v_str || chr(39) || 'USER_DB_LINKS'|| chr(39) || ',' || chr(39) || 'ALL_DB_LINKS'|| chr(39) || '))' || chr(10); -- removed by Arnaldo because IFS use them.
		v_str:=v_str || ' and grantee not in ('|| chr(39) || 'DBA'|| chr(39) || ','|| chr(39) || 'SYS'|| chr(39) || ','|| chr(39) || 'SYSTEM'|| chr(39) || ',' || chr(10); 
		v_str:=v_str || chr(39) || 'SYSMAN'|| chr(39) || ','|| chr(39) || 'AQ_ADMINISTRATOR_ROLE'|| chr(39) || ','|| chr(39) || 'SELECT_CATALOG_ROLE'|| chr(39) || ',' || chr(10); 
		v_str:=v_str || chr(39) || 'DELETE_CATALOG_ROLE'|| chr(39) || ','|| chr(39) || 'IFSAPP'|| chr(39) || ')' || chr(10); 
		v_str:=v_str || ' and grantee not in ( ' || chr(10);
		v_str:=v_str || ' select username from dba_users where account_status <> '|| chr(39) || 'OPEN' || chr(39) || ')';
		
		execute immediate v_str into v_return;
		
		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;		

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_security_risk_tables;	



	/*==============================================================*/
	/* Disabled Constraints											*/
	/*==============================================================*/
	function get_disabled_constraints(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := DISABLED_CONSTRAINTS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := DISABLED_CONSTRAINTS_C;
		else
			v_critical := p_critical;
		end if;				
		
		v_str:='select count(1) x from dba_constraints where status = ' || chr(39) || 'STATUS' || chr(39) || ' and owner =' || chr(39) || OWNER_APP || chr(39); 		
		
		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_disabled_constraints;	



	/*==============================================================*/
	/* Number of Archives (last 24 hours)							*/
	/*==============================================================*/
	function get_number_archives(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := NUMBER_ARCHIVES_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := NUMBER_ARCHIVES_C;
		else
			v_critical := p_critical;
		end if;						
		
		v_str:='select count(1) x from gv$archived_log where DEST_ID=1 and trunc(COMPLETION_TIME) = trunc(SYSDATE)';
		
		execute immediate v_str into v_return;

		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;		

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_number_archives;	


	
	/*==============================================================*/
	/* Size of Archives (last 24 hours)								*/
	/*==============================================================*/
	function get_size_archives(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SIZE_ARCHIVES_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SIZE_ARCHIVES_C;
		else
			v_critical := p_critical;
		end if;						
		
		v_str:='select trunc(sum((BLOCKS*BLOCK_SIZE)/1024/1024)) x from gv$archived_log where DEST_ID=1 and trunc(COMPLETION_TIME) = trunc(SYSDATE)';
		
		execute immediate v_str into v_return;

		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;		
		
		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_size_archives;	

	

	/*==============================================================*/
	/* Standby Check Error											*/
	/*==============================================================*/
	function get_standby_check_error(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := STANDBY_CHECK_ERROR_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := STANDBY_CHECK_ERROR_C;
		else
			v_critical := p_critical;
		end if;						
		
		v_str:='select count(1) x from gv$dataguard_status where (ERROR_CODE!=0 or SEVERITY=' || chr(39) || 'Error' || chr(39) || ') and TIMESTAMP > SYSDATE - 1/24';
		
		execute immediate v_str into v_return;
		
		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;				

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_standby_check_error;

	
	
	/*==============================================================*/
	/* Standby Check Lag											*/
	/*==============================================================*/
	function get_standby_check_lag(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := STANDBY_CHECK_LAG_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := STANDBY_CHECK_LAG_C;
		else
			v_critical := p_critical;
		end if;						
		
		v_str:='select nvl((v_day*60*24)+(v_hour*60)+(v_minute),0) x from ( ' || chr(10);
		v_str:=v_str || ' select to_number(substr(dg.value,2,2)) v_day, to_number(substr(dg.value,5,2)) v_hour, to_number(substr(dg.value,8,2)) v_minute ' || chr(10); 
		v_str:=v_str || ' from v$dataguard_stats dg, v$database db ' || chr(10);
		v_str:=v_str || ' where dg.source_dbid = db.dbid ' || chr(10);
		v_str:=v_str || ' and db.database_role = ' || chr(39) || 'PHYSICAL STANDBY' || chr(39) || chr(10);
		v_str:=v_str || ' and dg.name = ' || chr(39) || 'apply lag' || chr(39) || ' )';
		
		execute immediate v_str into v_return;
		
		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;				

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_standby_check_lag;

	
	
	/*==============================================================*/
	/* Database Allocated											*/
	/*==============================================================*/
	function get_database_allocated(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := DATABASE_ALLOCATED_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := DATABASE_ALLOCATED_C;
		else
			v_critical := p_critical;
		end if;						
		
		v_str:='select round((sum(bytes)/1024/1024/1024),2) x from dba_data_files';
		
		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_database_allocated;



	/*==============================================================*/
	/* Database Used												*/
	/*==============================================================*/
	function get_database_used(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := DATABASE_USED_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := DATABASE_USED_C;
		else
			v_critical := p_critical;
		end if;						
		
		v_str:='select round((sum(bytes)/1024/1024/1024),2) x from dba_segments';
		
		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_database_used;

	

	/*==============================================================*/
	/* Backup Time													*/
	/*==============================================================*/
	function get_backup_time(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := BACKUP_TIME_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := BACKUP_TIME_C;
		else
			v_critical := p_critical;
		end if;						
		
		v_str:='select trunc(elapsed_seconds/3600) x from V$RMAN_BACKUP_JOB_DETAILS ' || chr(10);
		v_str:=v_str || ' where INPUT_TYPE=' || chr(39) || 'DB INCR' || chr(39) || ' and status = '|| chr(39) ||'COMPLETED'|| chr(39) || chr(10);
		v_str:=v_str || ' and session_key = (select max(session_key) from V$RMAN_BACKUP_JOB_DETAILS ' || chr(10);  
		v_str:=v_str || ' where INPUT_TYPE=' || chr(39) || 'DB INCR' || chr(39) || ' and status = '|| chr(39) ||'COMPLETED'|| chr(39) || ')';		
		
		execute immediate v_str into v_return;

		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;		

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				elsif v_return > v_warning and v_return < v_critical then 
					v_return:=1;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_backup_time;



	/*==============================================================*/
	/* Backup Status												*/
	/*==============================================================*/
	function get_backup_status(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := BACKUP_STATUS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := BACKUP_STATUS_C;
		else
			v_critical := p_critical;
		end if;
		
		v_str:='select count(1) x from V$RMAN_BACKUP_JOB_DETAILS ' || chr(10);
		v_str:=v_str || ' where status = '|| chr(39) ||'FAILED'|| chr(39) || chr(10);
		v_str:=v_str || ' and trunc(START_TIME) = trunc(SYSDATE)';  
		
		execute immediate v_str into v_return;
		
		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;		

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_backup_status;
	
	
	/*==============================================================*/
	/* Backup Frequency												*/
	/*==============================================================*/
	function get_backup_frequency(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null, p_bkptag in varchar2 default null, p_perioddays in number default 35) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := BACKUP_FREQUENCY_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := BACKUP_FREQUENCY_C;
		else
			v_critical := p_critical;
		end if;		

		v_str:='select max(diff) x ' || chr(10);
		v_str:=v_str || 'from ' || chr(10);
		v_str:=v_str || '( ' || chr(10);
		v_str:=v_str || '	select a.max_date, b.min_date, (a.max_date - b.min_date) diff ' || chr(10);
		v_str:=v_str || '	from ' || chr(10);
		v_str:=v_str || '	( ' || chr(10);
		v_str:=v_str || '		select max_date, rownum max_rownum from ' || chr(10);
		v_str:=v_str || '		( ' || chr(10);
		v_str:=v_str || '			select DISTINCT trunc(completion_time) max_date ' || chr(10);
		v_str:=v_str || '			from v$backup_files  ' || chr(10);
		v_str:=v_str || '			where BS_TAG = '|| chr(39) || p_bkptag || chr(39) || chr(10);
		v_str:=v_str || '			and file_type = '|| chr(39) ||'PIECE'|| chr(39) || chr(10);
		v_str:=v_str || '			and trunc(completion_time) > sysdate -' || p_perioddays || chr(10);
		v_str:=v_str || '			order by 1 ' || chr(10);
		v_str:=v_str || '		) order by 1 ' || chr(10);
		v_str:=v_str || '	) a, ' || chr(10);
		v_str:=v_str || '	( ' || chr(10);
		v_str:=v_str || '		select min_date, rownum min_rownum from  ' || chr(10);
		v_str:=v_str || '		( ' || chr(10);
		v_str:=v_str || '			select DISTINCT trunc(completion_time) min_date ' || chr(10);
		v_str:=v_str || '			from v$backup_files  ' || chr(10);
		v_str:=v_str || '			where BS_TAG = '|| chr(39) || p_bkptag || chr(39) || chr(10);
		v_str:=v_str || '			and file_type = '|| chr(39) ||'PIECE'|| chr(39) || chr(10);
		v_str:=v_str || '			and trunc(completion_time) > sysdate -' || p_perioddays || chr(10);
		v_str:=v_str || '			order by 1 ' || chr(10);
		v_str:=v_str || '		) order by 1 ' || chr(10);
		v_str:=v_str || '	) b ' || chr(10);
		v_str:=v_str || '	where b.min_rownum=a.max_rownum-1 ' || chr(10);
		v_str:=v_str || '	union all ' || chr(10);
		v_str:=v_str || '	select sysdate max_date,  max(trunc(completion_time)) min_date, trunc((sysdate - max(trunc(completion_time)))) diff ' || chr(10);
		v_str:=v_str || '	from v$backup_files  ' || chr(10);
		v_str:=v_str || '	where BS_TAG = '|| chr(39) || p_bkptag || chr(39) || chr(10);
		v_str:=v_str || '	and file_type = '|| chr(39) ||'PIECE'|| chr(39) || chr(10);
		v_str:=v_str || ')';
		
		execute immediate v_str into v_return;
		
		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;		

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_backup_frequency;
	


	/*==============================================================*/
	/* Tablespace PCT Used											*/
	/*==============================================================*/
	function get_tbs_pctused(p_tbs in varchar2 default 'SYSTEM', p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := TBS_PCTUSED_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := TBS_PCTUSED_C;
		else
			v_critical := p_critical;
		end if;

		if p_tbs <> 'TEMP' then
			v_str:='SELECT MAX(ROUND(( SUM (total_mb)- SUM (free_mb))/ SUM (max_mb)*100)) x ' || chr(10);
			v_str:=v_str || 'FROM ( ' || chr(10);
			v_str:=v_str || 'SELECT tablespace_name, SUM (bytes)/1024/1024 FREE_MB, ' || chr(10);
			v_str:=v_str || '0 TOTAL_MB, 0 MAX_MB ' || chr(10);
			v_str:=v_str || 'FROM dba_free_space ' || chr(10);
			v_str:=v_str || 'where tablespace_name = ' || chr(39) || p_tbs  || chr(39) || chr(10);
			v_str:=v_str || 'GROUP BY tablespace_name ' || chr(10);
			v_str:=v_str || 'UNION ALL ' || chr(10);
			v_str:=v_str || 'SELECT tablespace_name, 0 CURRENT_MB, ' || chr(10);
			v_str:=v_str || 'SUM (bytes)/1024/1024 TOTAL_MB, ' || chr(10);
			v_str:=v_str || 'SUM ( DECODE (maxbytes,0,bytes, maxbytes))/1024/1024 MAX_MB ' || chr(10);
			v_str:=v_str || 'FROM dba_data_files ' || chr(10);
			v_str:=v_str || 'where tablespace_name = '|| chr(39) || p_tbs || chr(39) || chr(10);
			v_str:=v_str || 'GROUP BY tablespace_name) ' || chr(10);
			v_str:=v_str || 'GROUP BY tablespace_name ' || chr(10);	
		
			execute immediate v_str into v_return;		

			if p_type = 'status' then
				if v_critical <> -1 then		-- ignore threshold
					if v_return > v_critical then 
						v_return:=2;
					elsif v_return > v_warning and v_return < v_critical then 
						v_return:=1;
					else
						v_return:=0;
					end if;
				else
					v_return:=0;
				end if;		
			end if;
			
			return v_return;
		end if;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_tbs_pctused;

	

	/*==============================================================*/
	/* File I/O Activity											*/
	/*==============================================================*/
	function get_file_io(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := FILE_IO_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := FILE_IO_C;
		else
			v_critical := p_critical;
		end if;

		v_str:='select sum(phyrds+phywrts) sum_io from v$filestat';
		
		execute immediate v_str into v_return;
		
		-- Avoiding misunderstand value
		if v_return is null then
			v_return:= 0;
		end if;		

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_file_io;	


	
	/*==============================================================*/
	/* SGA Buffer Cache												*/
	/*==============================================================*/
	function get_sga_buffer_cache(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SGA_BUFFER_CACHE_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SGA_BUFFER_CACHE_C;
		else
			v_critical := p_critical;
		end if;

		v_str:='SELECT to_char(ROUND(SUM(decode(pool,NULL,decode(name,' || chr(39) || 'db_block_buffers' || chr(39) || ' ,(bytes)/(1024*1024),' || chr(39) ||'buffer_cache' || chr(39) || ',(bytes)/(1024*1024),0),0)),2)) sga_bufcache from v$sgastat';
		
		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_sga_buffer_cache;		
	


	/*==============================================================*/
	/* SGA Fixed													*/
	/*==============================================================*/
	function get_sga_fixed(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SGA_FIXED_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SGA_FIXED_C;
		else
			v_critical := p_critical;
		end if;
		
		v_str:='select to_char(round(sum(decode(pool,null,decode(name,'|| chr(39) || 'fixed_sga'|| chr(39) || ',(bytes)/(1024*1024),0),0)),2)) sga_fixed from v$sgastat';
		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_sga_fixed;		



	/*==============================================================*/
	/* SGA Java Pool												*/
	/*==============================================================*/
	function get_sga_java_pool(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SGA_JAVA_POOL_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SGA_JAVA_POOL_C;
		else
			v_critical := p_critical;
		end if;
		
		v_str:='select to_char(round(sum(decode(pool,'|| chr(39) || 'java pool'|| chr(39) || ',(bytes)/(1024*1024),0)),2)) sga_jpool from v$sgastat';		
		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_sga_java_pool;		



	/*==============================================================*/
	/* SGA Large Pool												*/
	/*==============================================================*/
	function get_sga_large_pool(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SGA_LARGE_POOL_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SGA_LARGE_POOL_C;
		else
			v_critical := p_critical;
		end if;
		
		v_str:='SELECT to_char(ROUND(SUM(decode(pool,'|| chr(39) || 'large pool'|| chr(39) || ',(bytes)/(1024*1024),0)),2)) sga_lpool from v$sgastat';
		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_sga_large_pool;		
	
	
	
	/*==============================================================*/
	/* SGA Log Buffer												*/
	/*==============================================================*/
	function get_sga_log_buffer(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SGA_LOG_BUFFER_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SGA_LOG_BUFFER_C;
		else
			v_critical := p_critical;
		end if;
		
		v_str:='select to_char(round(sum(decode(pool,'|| chr(39) || 'shared pool'|| chr(39) || ',decode(name,' || chr(10); 
		v_str:=v_str || chr(39) ||'library cache'|| chr(39) || ',0,'|| chr(39) || 'dictionary cache'|| chr(39) || ',0,'|| chr(10); 
		v_str:=v_str || chr(39) || 'free memory'|| chr(39) || ',0,'|| chr(39) || 'sql area'|| chr(39) || ',0,(bytes)/(1024*1024)),0)),2)) pool_misc from v$sgastat';
		
		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_sga_log_buffer;



	/*==============================================================*/
	/* SGA Shared Pool												*/
	/*==============================================================*/
	function get_sga_shared_pool(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	number;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		v_return:=0;
		if p_warning is null then
			v_warning := SGA_SHARED_POOL_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := SGA_SHARED_POOL_C;
		else
			v_critical := p_critical;
		end if;
		
		v_str:='select to_char(round(sum(decode(pool,null,decode(name,'|| chr(39) || 'log_buffer'|| chr(39) || ',(bytes)/(1024*1024),0),0)),2)) sga_lbuffer from v$sgastat';
		execute immediate v_str into v_return;

		if p_type = 'status' then
			if v_critical <> -1 then		-- ignore threshold
				if v_return > v_critical then 
					v_return:=2;
				else
					v_return:=0;
				end if;
			else
				v_return:=0;
			end if;		
		end if;
		
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			return -1;
    end get_sga_shared_pool;
	

	/*==============================================================*/
	/* Top 1 foreground event										*/
	/*==============================================================*/
	function get_top1_event(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return varchar is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	varchar2(100);
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin
		v_str:='select "Event" x from ( ' || chr(10);
		v_str:=v_str || ' select rownum num_line, ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || ' order by inst_id, snap_id ' || chr(10);
		v_str:=v_str || ' ) where num_line = 1';
		
		
		execute immediate v_str into v_return;
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
    end get_top1_event;	
	

	/*==============================================================*/
	/* Top 2 foreground event										*/
	/*==============================================================*/
	function get_top2_event(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return varchar is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	varchar2(100);
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin
		v_str:='select "Event" x from ( ' || chr(10);
		v_str:=v_str || ' select rownum num_line, ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || ' order by inst_id, snap_id ' || chr(10);
		v_str:=v_str || ' ) where num_line = 2';
		
		
		execute immediate v_str into v_return;
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
    end get_top2_event;	


	/*==============================================================*/
	/* Top 3 foreground event										*/
	/*==============================================================*/
	function get_top3_event(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return varchar is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	varchar2(100);
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin
		v_str:='select "Event" x from ( ' || chr(10);
		v_str:=v_str || ' select rownum num_line, ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || ' order by inst_id, snap_id ' || chr(10);
		v_str:=v_str || ' ) where num_line = 3';
		
		
		execute immediate v_str into v_return;
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
    end get_top3_event;	


	/*==============================================================*/
	/* Top 4 foreground event										*/
	/*==============================================================*/
	function get_top4_event(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return varchar is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	varchar2(100);
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin
		v_str:='select "Event" x from ( ' || chr(10);
		v_str:=v_str || ' select rownum num_line, ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || ' order by inst_id, snap_id ' || chr(10);
		v_str:=v_str || ' ) where num_line = 4';
		
		
		execute immediate v_str into v_return;
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
    end get_top4_event;	



	/*==============================================================*/
	/* Top 5 foreground event										*/
	/*==============================================================*/
	function get_top5_event(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return varchar is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	varchar2(100);
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin
		v_str:='select "Event" x from ( ' || chr(10);
		v_str:=v_str || ' select rownum num_line, ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || ' order by inst_id, snap_id ' || chr(10);
		v_str:=v_str || ' ) where num_line = 5';
		
		
		execute immediate v_str into v_return;
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
    end get_top5_event;	



	/*==============================================================*/
	/* Top 1 foreground value										*/
	/*==============================================================*/
	function get_top1_value(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	varchar2(100);
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin
		v_str:='select "% DB time" x from ( ' || chr(10);
		v_str:=v_str || ' select rownum num_line, ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || ' order by inst_id, snap_id ' || chr(10);
		v_str:=v_str || ' ) where num_line = 1';
		
		
		execute immediate v_str into v_return;
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
    end get_top1_value;	
	

	/*==============================================================*/
	/* Top 2 foreground value										*/
	/*==============================================================*/
	function get_top2_value(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	varchar2(100);
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin
		v_str:='select "% DB time" x from ( ' || chr(10);
		v_str:=v_str || ' select rownum num_line, ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || ' order by inst_id, snap_id ' || chr(10);
		v_str:=v_str || ' ) where num_line = 2';
		
		
		execute immediate v_str into v_return;
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
    end get_top2_value;	


	/*==============================================================*/
	/* Top 3 foreground value										*/
	/*==============================================================*/
	function get_top3_value(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	varchar2(100);
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin
		v_str:='select "% DB time" x from ( ' || chr(10);
		v_str:=v_str || ' select rownum num_line, ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || ' order by inst_id, snap_id ' || chr(10);
		v_str:=v_str || ' ) where num_line = 3';
		
		
		execute immediate v_str into v_return;
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
    end get_top3_value;	


	/*==============================================================*/
	/* Top 4 foreground value										*/
	/*==============================================================*/
	function get_top4_value(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	varchar2(100);
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin
		v_str:='select "% DB time" x from ( ' || chr(10);
		v_str:=v_str || ' select rownum num_line, ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || ' order by inst_id, snap_id ' || chr(10);
		v_str:=v_str || ' ) where num_line = 4';
		
		
		execute immediate v_str into v_return;
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
    end get_top4_value;	



	/*==============================================================*/
	/* Top 5 foreground value										*/
	/*==============================================================*/
	function get_top5_value(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	varchar2(100);
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin
		v_str:='select "% DB time" x from ( ' || chr(10);
		v_str:=v_str || ' select rownum num_line, ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || ' order by inst_id, snap_id ' || chr(10);
		v_str:=v_str || ' ) where num_line = 5';		
		
		execute immediate v_str into v_return;
		return v_return;
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
    end get_top5_value;	
	
	

	/*==============================================================*/
	/* Top 5 foreground events										*/
	/*==============================================================*/
	function get_top5_events(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return SYS_REFCURSOR is		
		-- program variables
		v_warning	number;
		v_critical	number;
		v_str 		varchar2(4000);
		v_return	SYS_REFCURSOR;
		v_ora_erro 	integer;
        v_ora_mens 	varchar2(200);
	begin		
		if p_warning is null then
			v_warning := TOP5_EVENTS_W;
		else
			v_warning := p_warning;
		end if;

		if p_critical is null then
			v_critical := TOP5_EVENTS_C;
		else
			v_critical := p_critical;
		end if;

		v_str:='select  ' || chr(10);
		v_str:=v_str || ' event_name "Event", ' || chr(10);
		v_str:=v_str || ' total_waits "Waits", ' || chr(10);
		v_str:=v_str || ' time_waited "Time(s)", ' || chr(10);
		v_str:=v_str || ' round((time_waited/total_waits)*1000) "Avg wait(ms)", ' || chr(10);
		v_str:=v_str || ' round((time_waited/db_time)*100, 2) "% DB time", ' || chr(10);
		v_str:=v_str || ' substr(wait_class, 1, 15) "Wait Class" ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  inst_id, ' || chr(10);
		v_str:=v_str || '  snap_id, to_char(begin_snap, ' || chr(39) || 'DD-MM-YY hh24:mi:ss' || chr(39) ||') begin_snap, ' || chr(10);
		v_str:=v_str || '  to_char(end_snap, '|| chr(39) ||'hh24:mi:ss'|| chr(39) ||') end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited, ' || chr(10);
		v_str:=v_str || '  dense_rank() over (partition by inst_id, snap_id order by time_waited desc)-1 wait_rank, ' || chr(10);
		v_str:=v_str || '  max(time_waited) over (partition by inst_id, snap_id) db_time ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || 'select ' || chr(10);
		v_str:=v_str || '  s.instance_number inst_id, ' || chr(10);
		v_str:=v_str || '  s.snap_id, ' || chr(10);
		v_str:=v_str || '  s.begin_interval_time begin_snap, ' || chr(10);
		v_str:=v_str || '  s.end_interval_time end_snap, ' || chr(10);
		v_str:=v_str || '  event_name, ' || chr(10);
		v_str:=v_str || '  wait_class, ' || chr(10);
		v_str:=v_str || '  total_waits-lag(total_waits, 1, total_waits) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) total_waits, ' || chr(10);
		v_str:=v_str || '  time_waited-lag(time_waited, 1, time_waited) over ' || chr(10);
		v_str:=v_str || '   (partition by s.startup_time, s.instance_number, stats.event_name order by s.snap_id) time_waited, ' || chr(10);
		v_str:=v_str || '  min(s.snap_id) over (partition by s.startup_time, s.instance_number, stats.event_name) min_snap_id ' || chr(10);
		v_str:=v_str || 'from ( ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, event_name, wait_class, total_waits_fg total_waits, round(time_waited_micro_fg/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_system_event ' || chr(10);
		v_str:=v_str || '  where wait_class not in ('|| chr(39) ||'Idle'|| chr(39) ||','|| chr(39) || 'System I/O'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ' union all ' || chr(10);
		v_str:=v_str || ' select dbid, instance_number, snap_id, stat_name event_name, null wait_class, null total_waits, round(value/1000000, 2) time_waited ' || chr(10);
		v_str:=v_str || '  from dba_hist_sys_time_model ' || chr(10);
		v_str:=v_str || '  where stat_name in ('|| chr(39) ||'DB CPU'|| chr(39) ||','|| chr(39) || 'DB time'|| chr(39) ||') ' || chr(10);
		v_str:=v_str || ') stats, dba_hist_snapshot s ' || chr(10);
		v_str:=v_str || ' where stats.instance_number=s.instance_number ' || chr(10);
		v_str:=v_str || '  and stats.snap_id=s.snap_id ' || chr(10);
		v_str:=v_str || '  and stats.dbid=s.dbid ' || chr(10);
		v_str:=v_str || '  and s.dbid=(select dbid from v$database) ' || chr(10);
		v_str:=v_str || '  and s.instance_number=1 ' || chr(10);
		v_str:=v_str || '  and stats.snap_id between (select max(snap_id)-1 from dba_hist_snapshot) and (select max(snap_id) from dba_hist_snapshot) ' || chr(10);
		v_str:=v_str || ') where snap_id > min_snap_id and nvl(total_waits,1) > 0 ' || chr(10);
		v_str:=v_str || ') where event_name!='|| chr(39) ||'DB time'|| chr(39) ||' and wait_rank <= 5 ' || chr(10);
		v_str:=v_str || 'order by inst_id, snap_id ';		
		
		open v_return for v_str;		
		return v_return;
		close v_return; 
		
		exception
			when others then 			
			v_ora_erro := sqlcode;
			v_ora_mens := sqlerrm;
			raise_application_error(-20000, '[ERROR] Error code : '||v_ora_erro||', Message : '||v_ora_mens);
			close v_return; 
    end get_top5_events;	
	
	
end ORCL_MONITORING; 
/

show errors;



