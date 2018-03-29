--------------------------------------------------------
--  File created - October-19-2017   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package ORCL_MONITORING
--------------------------------------------------------
CREATE OR REPLACE PACKAGE "ORCL_MONITORING" as
	function get_db_status(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_hitratio_buffer_cache(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_hitratio_library_cache(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_hitratio_row_cache(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_hitratio_pga(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_hitratio_soft_parse(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_hitratio_redo_allocation(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_hitratio_memory_sorts(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_hitratio_without_parse(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_hitratio_process_limit(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_hitratio_session_limit(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_current_logons(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_active_sessions(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_current_open_cursors(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_database_wait_time(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_shared_pool_free(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_database_cpu_time(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_temp_space_used(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_mbps(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_iops(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_scan_error_db(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_redo_log_switch(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_locked_objects(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_invalid_objects(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_statistics(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_restore_point_active(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_materialized_view(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_index_unusable(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_security_dba(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_security_any(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_security_risk_tables(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_disabled_constraints(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_number_archives(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_size_archives(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_standby_check_error(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_standby_check_lag(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_database_allocated(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_database_used(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_backup_time(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_backup_status(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_backup_frequency(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null, p_bkptag in varchar2 default null, p_perioddays in number default 35) return number;
	function get_tbs_pctused(p_tbs in varchar2 default 'SYSTEM', p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_file_io(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_sga_buffer_cache(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_sga_fixed(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_sga_java_pool(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_sga_large_pool(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_sga_log_buffer(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_sga_shared_pool(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_top1_event(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return varchar;
	function get_top2_event(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return varchar;
	function get_top3_event(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return varchar;
	function get_top4_event(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return varchar;
	function get_top5_event(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return varchar;
	function get_top1_value(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_top2_value(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_top3_value(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_top4_value(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_top5_value(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return number;
	function get_top5_events(p_type in varchar2 default 'metric', p_warning in number default null, p_critical in number default null) return SYS_REFCURSOR;
end ORCL_MONITORING;
/

show errors;
