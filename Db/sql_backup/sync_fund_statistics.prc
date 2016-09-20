create or replace procedure smzj.sync_fund_statistics is
  -- *************************************************************************
-- SYSTEM:      托管服务平台
-- SUBSYS:       私募之家
-- PROGRAM:      sync_fund_statistics
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步产品规模
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       庞作青
-- CREATE DATE:  201601-18
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
  v_msg   varchar2(4000);
  pre_day varchar2(10);

begin
  execute immediate 'truncate table busI_FUND_STATS';
  
  select getpreworkday(to_char(sysdate-1,'yyyymmdd')) into pre_day from dual;
  insert into busI_FUND_STATS(Id,Fund_Code,Fund_Name,Com_Code,Com_Name,Rs,Gm,Rq,Create_Date,cpid)
        select id_seq.nextval, t.product_no ,t.name ,c.insti_code,c.cp_name,m.rs,m.gm,m.qrrq,sysdate,c.id

      from BUSI_PRODUCT t,Busi_Company  c,(
      select rs,qrrq,gm,jjdm from (select  t.rs ,t.gm,t.qrrq,t.jjdm,  row_number() over( partition by t.jjdm order by t.qrrq desc ) rn  from zsta.ut_集合理财产品人数规模表@ta_dblink t)
             where rn =1
      )m
     where t.cp_id=c.id  and t.is_delete='0' and m.jjdm=t.product_no and m.qrrq >=pre_day;



  v_msg :='同步成功！';
  insert into t_fund_job_running_log(job_name,job_running_log) values('产品规模',v_msg);
         commit;
  exception
    when others then
      v_msg :='同步失败，原因：'|| sqlcode || ':' || sqlerrm ||dbms_utility.format_error_stack;
      rollback;
      insert into t_fund_job_running_log(job_name,job_running_log) values('产品规模',v_msg);
      commit;

end sync_fund_statistics;
/

