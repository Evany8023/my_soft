create or replace procedure smzj.SYNC_COMPANY_INFO
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_COMPANY_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步公司信息
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-28
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
AS
    v_comp_count      integer; --基金公司数量
    v_msg             varchar2(2000);
    v_table_id        varchar2(32);
    --v_sql             varchar2(100):= 'truncate table BUSI_COMPANY';
    v_job_name        varchar2(100):= '同步公司信息';
    
    cursor fundCompany_cur is select t.distributorname, t.distributorcode, t.distributortp, t.tel 
    from zsta.distributor@TA_DBLINK t where lower(nvl(t.sywj_kzm, '.TXT')) like '%xls%';
    
    v_distributorname BUSI_COMPANY.CP_NAME%type; -- 公司名称
    v_distributorcode BUSI_COMPANY.INSTI_CODE%type; -- 机构代码
    v_distributortype BUSI_COMPANY.CP_TYPE%type;      -- 机构类型
    v_tel             BUSI_COMPANY.TELEPHONE%type;    -- 固定电话
BEGIN
    --execute immediate v_sql;
    open fundCompany_cur;
    loop
        fetch fundCompany_cur into v_distributorname, v_distributorcode, v_distributortype, v_tel;
        if fundCompany_cur % notfound then
            exit;
        end if;
 
        select count(*) into v_comp_count from BUSI_COMPANY t where t.insti_code = v_distributorcode;
        if v_comp_count = 0 then  --新增
           select lower(SYS_GUID()) into v_table_id  from dual;
           -- select SYNC_TASK_SEQ.nextVal into v_table_id from dual;
            insert into BUSI_COMPANY
            (
                id,
                cp_name,     --公司名称
                insti_code,  --机构代码
                cp_type,     --机构类型
                telephone,   --固定电话
                is_examine, -- 是否审核（0：未审核，1：审核）
                examine_date, -- 审核日期
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
             ); -- 因 ta只有公司的名称简写，需要保存名称大写
        --else --已有的，只更新部分信息
         --   update BUSI_COMPANY 
         --   set cp_name = v_distributorname,
          --      cp_type = v_distributortype,
        --        telephone = v_tel, 
         --       is_examine = '1', --已审核
         --       examine_date = sysdate,
         --       update_by = 'userjob',
         --       update_date = sysdate
          --  where insti_code = v_distributorcode;
        end if;
    end loop;
    close fundCompany_cur;
    
    v_msg :='同步成功';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
EXCEPTION
    when others then
        rollback;
        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_COMPANY_INFO;
/

