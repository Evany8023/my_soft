CREATE OR REPLACE PROCEDURE SMZJ.SYNC_TRADE_PRODUCT_COMCODE
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_CLEAR_PRODUCT
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步清盘产品
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       卢雅琴
-- CREATE DATE:  2016-01-05
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
is
    v_msg                        varchar2(1000);
    v_job_name                   varchar2(100):= '同步需要代销和直销的的产品';

    v_product_no                varchar2(200);
    v_comcode_no                 varchar2(200);
    v_produc_count              integer;
    v_com_count              integer;

begin        --同步清盘产品信息开始
  delete from  BUSI_TRADE_PRODUCT_COM;

v_msg :='同步需要代销和直销的的产品';
insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
commit;

EXCEPTION
    when others then
        rollback;

        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm ||v_product_no || v_comcode_no || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_TRADE_PRODUCT_COMCODE;
/

