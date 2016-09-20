create or replace procedure smzj.test is
v_id varchar(100);
v_count integer;
v_active_time varchar(2000);
v_msg varchar(2000);
v_job_log_name varchar(2000) ;
cursor fund_cust_cur  is select  id from T_FUND_LOg_GGG where id is not null  ;
begin
  v_job_log_name:='test';
 open fund_cust_cur ;
 loop
    fetch fund_cust_cur into v_id;
    if fund_cust_cur%notfound then
      exit;
    end if;
    
    select count(1) into v_count  from  sys_manager_log l where l.method ='激活投资人'  and l.params like '%'||v_id||'%' ;
    if v_count > 0 then
      select wmsys.wm_concat(to_char(l.create_date,'yyyymmdd')) into  v_active_time from  sys_manager_log l where l.method ='激活投资人'  and l.params like '%'||v_id||'%'  ;
      update T_FUND_LOg_GGG t set t.oper_content=v_active_time where id=v_id;
    end if;
    
    
end loop;

  close fund_cust_cur;   
  
  commit; 
 exception 
   when others then
      rollback;
      v_msg :='同步失败，原因：'|| sqlcode || ':' || sqlerrm || '  '||v_id || dbms_utility.format_error_backtrace() ;
      insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);

  commit;
end test;
/

