create or replace procedure smzj.SYNC_QUICKFEDEEM_FULLDOSE
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_QUICKFEDEEM_FULLDOSE
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  �賿�ĵ������ص���ؽ���ȷ�����ں�TAȫ��ͬ��
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       xiaxiaonan
-- CREATE DATE:  2015-12-2
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
is
    v_msg varchar2(1000  char );
    v_job_name varchar2(100):= 'SYNC_QUICKFEDEEM_FULLDOSE';
    v_sqdbh   busi_quick_sheet.sheet_no%type;
    v_date varchar(10 char);
    v_qrje  varchar2(20 char);
    v_qrrq  varchar2(20 char);
    v_cpdm  varchar2(20 char);


cursor data_cur  is 
select APPSHEETSERIALNO,f.CONFIRMEDAMOUNT,f.TRANSACTIONCFMDATE,f.FUNDCODE 
from zsta.C_ACK_TRANS_ZD@TA_DBLINK f;

    

begin 
   select to_char(sysdate,'yyyymmdd') into v_date from dual;  
    open data_cur ;
    loop
        fetch data_cur into v_sqdbh,v_qrje,v_qrrq,v_cpdm;
        if data_cur%notfound then
          exit;
        end if;
         
 
        update busi_quick_sheet t set t.AMOUNT=v_qrje ,t.CONFIRM_DATE=to_date(v_qrrq,'yyyy-MM-dd')
        where t.sheet_no = v_sqdbh and t.pt_no = v_cpdm;
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
        v_msg :='ͬ��ʧ�ܣ�ԭ��' ||v_date ||sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_QUICKFEDEEM_FULLDOSE;
/

