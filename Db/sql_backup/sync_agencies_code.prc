CREATE OR REPLACE PROCEDURE SMZJ.SYNC_AGENCIES_CODE
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_ACCT_ALL_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ��TA�����д���˽ļ��Ʒ�Ĵ���������Ϣ
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       xiaxn
-- CREATE DATE:  2016-03-18
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
is
    code                         varchar2(20);        --������������
    v_count                      number;                --�ж�˽ļ֮�����Ƿ��Ѵ��ڸ����ۻ���
    v_count1                     number;   
    v_recvdirectory              varchar2(100);         --����Ŀ¼
    v_name                       varchar2(100);         --���ۻ�������
    v_kzm                       varchar2(20);          --�ļ���չ��
    v_msg                        varchar2(1000);         
    v_job_name                   varchar2(100):= 'ͬ��TA�����д���˽ļ��Ʒ�Ĵ���������Ϣ';

cursor agencies_code is 
select distinct(distributor) from zsta.ut_��Ʒ_�����̱�@ta_dblink ut where exists (
select fundcode from zsta.fundinfo@ta_dblink  f where nvl(managercode,'88') <> '88' and f.fundcode = ut.fundcode) 
and distributor  in( 
select distributorcode from zsta.distributor@ta_dblink where sywj_kzm <> '.xls' or sywj_kzm is null );



begin        --ͬ���ͻ���Ϣ��ʼ
   open  agencies_code;
   loop
         fetch agencies_code into code;
         if agencies_code%notfound then
            exit;
         end if;
         
         select count(*) into v_count from distributor where distributorcode = code;
         if v_count=0 then    --˵��˽ļ֮����û�и����ۻ����������
            select substr(recvdirectory,8),SYWJ_KZM,distributorname into v_recvdirectory,v_kzm,v_name from zsta.distributor@ta_dblink 
            where distributorcode = code;
          
            insert into distributor(distributorcode,receivepath,fileextension,distributortype,distributorname) values
            (code,v_recvdirectory,v_kzm,'1',v_name);
            
            --TA���������ۻ���ʱ��ex_seat�����Ӧ�仯��Ҳ��Ҫͬ��
            select count(*) into v_count1 from ex_seat where tcode = code;
            if v_count1 = 0 then    --˵��ex_seat����û�и����ۻ�����Ϣ
                insert into ex_seat t 
                select * from zsta.ex_seat@ta_dblink ta where ta.tcode = code;
             
            end if;
            
          end if;
          
    end loop;
          
v_msg :='ͬ��TA�����д���˽ļ��Ʒ�Ĵ���������Ϣ�ɹ�';
 insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
commit;

EXCEPTION
    when others then
 
        rollback;

        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_AGENCIES_CODE;
/

