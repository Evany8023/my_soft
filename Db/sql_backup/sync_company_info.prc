create or replace procedure smzj.SYNC_COMPANY_INFO
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_COMPANY_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ����˾��Ϣ
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-28
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
AS
    v_comp_count      integer; --����˾����
    v_msg             varchar2(2000);
    v_table_id        varchar2(32);
    --v_sql             varchar2(100):= 'truncate table BUSI_COMPANY';
    v_job_name        varchar2(100):= 'ͬ����˾��Ϣ';
    
    cursor fundCompany_cur is select t.distributorname, t.distributorcode, t.distributortp, t.tel 
    from zsta.distributor@TA_DBLINK t where lower(nvl(t.sywj_kzm, '.TXT')) like '%xls%';
    
    v_distributorname BUSI_COMPANY.CP_NAME%type; -- ��˾����
    v_distributorcode BUSI_COMPANY.INSTI_CODE%type; -- ��������
    v_distributortype BUSI_COMPANY.CP_TYPE%type;      -- ��������
    v_tel             BUSI_COMPANY.TELEPHONE%type;    -- �̶��绰
BEGIN
    --execute immediate v_sql;
    open fundCompany_cur;
    loop
        fetch fundCompany_cur into v_distributorname, v_distributorcode, v_distributortype, v_tel;
        if fundCompany_cur % notfound then
            exit;
        end if;
 
        select count(*) into v_comp_count from BUSI_COMPANY t where t.insti_code = v_distributorcode;
        if v_comp_count = 0 then  --����
           select lower(SYS_GUID()) into v_table_id  from dual;
           -- select SYNC_TASK_SEQ.nextVal into v_table_id from dual;
            insert into BUSI_COMPANY
            (
                id,
                cp_name,     --��˾����
                insti_code,  --��������
                cp_type,     --��������
                telephone,   --�̶��绰
                is_examine, -- �Ƿ���ˣ�0��δ��ˣ�1����ˣ�
                examine_date, -- �������
                create_by,
                create_date,
                update_by,
                update_date,
                is_delete
             )
            values
            (
                v_table_id, --
                v_distributorname,    
                v_distributorcode,
                v_distributortype, 
                v_tel,
                '1',
                sysdate,
                'userjob',--create_by
                sysdate,--create_date
                'userjob',--update_by
                sysdate,--update_date
                '0'--is_delete
             ); -- �� taֻ�й�˾�����Ƽ�д����Ҫ�������ƴ�д
        --else --���еģ�ֻ���²�����Ϣ
         --   update BUSI_COMPANY 
         --   set cp_name = v_distributorname,
          --      cp_type = v_distributortype,
        --        telephone = v_tel, 
         --       is_examine = '1', --�����
         --       examine_date = sysdate,
         --       update_by = 'userjob',
         --       update_date = sysdate
          --  where insti_code = v_distributorcode;
        end if;
    end loop;
    close fundCompany_cur;
    
    v_msg :='ͬ���ɹ�';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
EXCEPTION
    when others then
        rollback;
        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_COMPANY_INFO;
/

