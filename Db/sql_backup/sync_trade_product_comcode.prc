CREATE OR REPLACE PROCEDURE SMZJ.SYNC_TRADE_PRODUCT_COMCODE
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_CLEAR_PRODUCT
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ�����̲�Ʒ
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       ¬����
-- CREATE DATE:  2016-01-05
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
is
    v_msg                        varchar2(1000);
    v_job_name                   varchar2(100):= 'ͬ����Ҫ������ֱ���ĵĲ�Ʒ';

    v_product_no                varchar2(200);
    v_comcode_no                 varchar2(200);
    v_produc_count              integer;
    v_com_count              integer;

begin        --ͬ�����̲�Ʒ��Ϣ��ʼ
  delete from  BUSI_TRADE_PRODUCT_COM;

v_msg :='ͬ����Ҫ������ֱ���ĵĲ�Ʒ';
insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
commit;

EXCEPTION
    when others then
        rollback;

        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm ||v_product_no || v_comcode_no || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_TRADE_PRODUCT_COMCODE;
/

