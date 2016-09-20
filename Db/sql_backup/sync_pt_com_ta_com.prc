CREATE OR REPLACE PROCEDURE SMZJ.SYNC_PT_COM_TA_COM
-- *************************************************************************
-- SUBSYS:       私募之家
-- PROGRAM:      SYNC_ACCT_ALL_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  将交易中的公司包括代销，直销，关联到具体的管理人下
-- INPUT:
-- OUTPUT:
-- AUTHOR:       庞作青
-- CREATE DATE:  2015-12-24
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
is
    v_msg                        varchar2(1000);
    v_job_name                   varchar2(100):= '代销、直销公司关联';
    v_fundcode   varchar(100 char);
    v_comcode  varchar(100 char);
    v_comname   varchar(100 char);
    v_com_id   varchar(32 char);
    v_pt_comcode varchar(100 char);
    v_pt_name varchar(100 char);
    v_source varchar(2 char);
    v_count integer;
    v_double_count integer;
   -- cursor com_cur is select t.pt_no ,t.insti_code from busi_trading_confirm t 
    --where exists (select z.fundcode from V_ZX_DX z where z.fundcode=t.pt_no and z.fundcode=t.insti_code)
     -- group by t.pt_no ,t.insti_code;
      
     --modify by xiaxn,20160706
  cursor com_cur is select t.pt_no ,t.insti_code from busi_trading_confirm t 
    where exists (select z.fundcode from V_ZX_DX z where z.fundcode=t.pt_no)
      group by t.pt_no ,t.insti_code;

      

begin
execute immediate 'truncate table busi_ptcom_ta_com'; -- 删除数据
 open com_cur;
      loop
            fetch com_cur into v_fundcode, v_comcode;
            if com_cur%notfound then
               exit;
            end if;

            select count(1) into v_count from Busi_Product p,busi_company c  where p.product_no=v_fundcode and c.id=p.cp_id;
            if v_count > 0 then

             select c.id,c.insti_code,c.cp_name into v_com_id,v_pt_comcode,v_pt_name from Busi_Product p,busi_company c  where p.product_no=v_fundcode and c.id=p.cp_id;
             select count(1) into v_count  from ta_all_company t where t.code=v_comcode;
             select count(1) into v_double_count from busi_ptcom_ta_com c where c.pt_comcode=v_pt_comcode and c.ta_comcode=v_comcode;

             if   v_count > 0 and v_double_count <1  then
                select t.name,t.source into v_comname,v_source  from ta_all_company t where t.code=v_comcode;
                 insert into busi_ptcom_ta_com(pt_comcode,pt_comname,ta_comcode,ta_comname,pt_comid,source)
                 values(v_pt_comcode,v_pt_name,v_comcode,v_comname,v_com_id,v_source);
             end if;




            end if;




end loop;
close com_cur;


v_msg :='代销、直销公司关联 成功';
 insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
commit;

EXCEPTION
    when others then
        if com_cur%isopen then
            close com_cur;
        end if;
        rollback;

        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_PT_COM_TA_COM;
/

