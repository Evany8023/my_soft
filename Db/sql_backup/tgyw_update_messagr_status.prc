create or replace procedure smzj.TGYW_UPDATE_MESSAGR_STATUS is
---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      TGYW_UPDATE_MESSAGR_STATUS
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       xiaxn
-- DESCRIPTION:  �ı�δɾ����δ���������ǰ����������������Ϣ״̬��
--               ����ˣ�������Ч���ڣ�-->�ѷ��������·���ʱ�䣩��
--               ����δ���֪ͨ-->�ѽ�����ÿ��12:00��ʱִ��
-- CREATE DATE:  2016-05-26
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
v_id             varchar2(100);      --֪ͨid
v_status         varchar2(100);      --֪ͨ״̬
v_effectivedate  varchar2(100);      --��Ч����
v_enddate        varchar2(100);      --ʧЧ����
v_today          varchar2(100);      --��������
v_job_name       varchar2(100):='TGYW_UPDATE_MESSAGR_STATUS';
v_msg            varchar2(1000);

--ȡδɾ����δ���������Ҳ��ǰ����������֪ͨ
cursor data_cur is select n.id,n.status,to_char(n.effective_date,'yyyyMMdd'),to_char(n.end_date,'yyyyMMdd')
                     from busi_message_notice n where n.is_delete<>'1' and n.status<>'4' and n.notice_method<>'1';

begin
  select to_char(sysdate,'yyyyMMdd') into v_today from dual;

  open data_cur;
  loop
      fetch data_cur into v_id,v_status,v_effectivedate,v_enddate;
      if data_cur%notfound then
          exit;
      end if;

      --���֪ͨ״̬�����ͨ�����ҳ�����Ч���ڣ�״̬����ѷ���
      if v_status='2' and  v_today>=v_effectivedate and v_today<=v_enddate then
          update busi_message_notice n set n.status='3',n.notice_date=to_date(v_today,'yyyy/MM/dd')  where  n.id=v_id;
      end if;

      --���֪ͨ״̬����δ��ˣ��������ʧЧ���ڣ��ĳ��ѽ���
      if v_status<>'0'  and v_today>v_enddate then
          update busi_message_notice n set n.status='4' where n.id=v_id;
      end if;

  end loop;
  close data_cur;

  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'ͬ���ɹ�');
  commit;

EXCEPTION
    when others then
        if data_cur%isopen then
            close data_cur;
        end if;
        rollback;

        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;


end TGYW_UPDATE_MESSAGR_STATUS;
/

