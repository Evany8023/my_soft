create or replace procedure smzj.sync_update_status is

---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      sync_update_status
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  ���¹�˾�Ƿ�ֹͣ¼��״̬�����²�Ʒ�Ƿ���ʱ������
-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

v_job_name varchar2(100) :='sync_update_status';
v_msg   varchar2(4000);

begin

     update busi_product set IS_TEMP_OPEN = '0'; --���²�Ʒ�Ƿ���ʱ������Ϊ����
     update busi_company set IS_SHEET = '0';     --���¹�˾�Ƿ�ֹͣ¼��Ϊ���ǡ�
     update busi_product_add t set t.open_record = '0';     --���²�Ʒ��¶Ȩ���ջ�
     --update busi_product set IS_MANAGE = '0'; 
     update Busi_Company c set c.is_quick=0;
     v_msg :='ͬ���ɹ���   ' ||     to_char(sysdate,'yyyyMMdd');
   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
 commit;
 exception
    when others then
      rollback;
      v_msg :='ͬ��ʧ�ܣ�ԭ��' || to_char(sysdate,'yyyyMMdd') || '     '  || sqlcode || ':' || sqlerrm  || dbms_utility.format_error_backtrace() ;
      insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
end sync_update_status;
/

