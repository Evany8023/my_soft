create or replace procedure smzj.sync_all_fund_value is

  v_count integer;
  v_msg   varchar2(4000);
  v_job_name varchar2(100) :='sync_all_fund_value';

  v_date      date;
  v_create_date varchar2(16);


begin

  select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name and t.job_status = 1;

  if v_count > 0  then
    v_msg :='任务执行中，不允许重复执行，返回!';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    return;
  end if;
  execute immediate 'truncate table BUSI_ALL_FUND_VAUES';
  --锁定
  update t_fund_job_status t set t.job_status = 1 where t.job_en_name = v_job_name;
  commit;

  select to_date('20140901','yyyymmdd') into v_date from dual;
  select to_char(sysdate,'yyyymmdd') into v_create_date from dual;
  select count(1)  into v_count from  BUSI_ALL_FUND_VAUES;
  

      insert into BUSI_ALL_FUND_VAUES(ID,NAV,ACCUMULATIVENAV,TRADEDAY,FUNDCODE,FUNDNAME,FUNDID,COMID)
       select 
         sync_task_seq.nextVal,
         case when a.nav<1 then rpad('0'||a.nav,6,'0') when a.nav = 1 then rpad(a.nav||'.',6,'0')  else rpad(a.nav,6,'0') end ,
         case when a.accumulativenav<1 then rpad('0'||a.accumulativenav,6,'0') when a.accumulativenav = 1 then rpad(a.accumulativenav||'.',6,'0')  else rpad(a.accumulativenav,6,'0') end,
         a.tradedate ,a.fundcode,p.name,p.id,p.cp_id
       from  zsta.uv_xx_fundnav@ta_dblink a inner join busi_product p on p.product_no=a.fundcode
       where  
           a.tradedate <'20140901' and a.nav is not null;
           
  
  commit;
  

      insert into BUSI_ALL_FUND_VAUES(ID,NAV,ACCUMULATIVENAV,TRADEDAY,FUNDCODE,FUNDNAME,FUNDID,COMID,WFSY,QRLJSY)
        
       select id_seq.nextVal,
        a.nav,
        a.accumulativenav,
        a.tradedate,
        a.fundcode,p.name,p.id,p.cp_id,a.mwfsy,a.qrnhsyl
    from v_fundnav@wbdb_link a inner join busi_product p on p.product_no=a.fundcode 
   where a.nav is not null
     and a.tradedate >= '20140901';
  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'同步成功');
  commit;
  exception
    when others then
       rollback;
      v_msg :='同步失败，原因：'|| sqlcode || ':' || sqlerrm;
     
      insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
      update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
      commit;

end sync_all_fund_value;
/

