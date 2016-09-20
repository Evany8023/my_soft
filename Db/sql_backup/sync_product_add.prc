create or replace procedure smzj.sync_product_add as

---- *************************************************************************
-- SUBSYS:     产品补充表初始化数据
-- PROGRAM:      sync_product_add
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       sunyang
-- DESCRIPTION:  同步产品表数据到产品补充表作初始化数据
-- CREATE DATE:  2015年12月21日16:38:45
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************



 v_msg   varchar2(1000);
 v_job_name varchar2(100):= '交收预估同步数据';

 v_table_id varchar2(32); -- 表主键id
 cur_ptid BUSI_PRODUCT.ID%type; -- 产品代码


 cursor cur_pro  is
select id FROM BUSI_PRODUCT;


BEGIN
  
    open cur_pro;
    loop
      fetch cur_pro into cur_ptid;
      

      if cur_pro%notfound then
        exit;
      end if;
      
      select sys_guid() into v_table_id from dual;

      insert into BUSI_PRODUCT_ADD(id,PRODUCT_ID) values (v_table_id,cur_ptid);

  end loop;
  close cur_pro;

  commit;

  exception
    when others then
        rollback;
        v_msg:=sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();
        insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
       commit;
end;
/

