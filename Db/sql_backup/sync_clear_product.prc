CREATE OR REPLACE PROCEDURE SMZJ.SYNC_CLEAR_PRODUCT
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
    v_job_name                   varchar2(100):= '同步清盘产品信息';



    v_xmdm                       varchar(20 char);               --产品代码
    v_xmbh_qtime                date;            --清盘日期
   -- v_count                      integer;  
    v_produc_count                      integer;                                      --查出来记录条数
    v_id                         BUSI_CLEAR_PRODUCT.id%type;               --产品ID
    v_cpid                       BUSI_CLEAR_PRODUCT.cp_id%type;            --私募公司ID
    v_name                       BUSI_CLEAR_PRODUCT.name%type;             --产品名称
    v_productno                  BUSI_CLEAR_PRODUCT.product_no%type;       --产品代码
    v_producttype                BUSI_CLEAR_PRODUCT.product_type%type;     --产品类型
    v_windupnetval              varchar(20 char);  --清盘净值



    cursor custinfo_cur is select t.vc_xmdm, t.d_xmbh_qtime from tgyyzx.v_ysmzj_xmxx@yy_dblimk t where t.d_xmbh_qtime is not null and not exists(select a.product_no from BUSI_CLEAR_PRODUCT a where a.product_no=t.vc_xmdm);



begin        --同步清盘产品信息开始
open custinfo_cur;
loop
  fetch custinfo_cur into v_xmdm, v_xmbh_qtime;
    if custinfo_cur%notfound then
      exit;
    end if;
   
  
    select count(1) into v_produc_count  from BUSI_PRODUCT pt where pt.product_no=v_xmdm;
  
    if v_produc_count > 0 then
      --  select count(1) into v_count from BUSI_ALL_FUND_VAUES n where n.FUNDCODE=v_xmdm and n.TRADEDAY = to_char(v_xmbh_qtime,'yyyyMMdd');
      -- if v_count>0 then
      --     v_windupnetval :='--'  ;
             --select n.nav into v_windupnetval from BUSI_ALL_FUND_VAUES n where n.FUNDCODE=v_xmdm and n.TRADEDAY = to_char(v_xmbh_qtime,'yyyyMMdd')  ;
      --   else 
      --     v_windupnetval :='--'  ;
      --  end if;

     v_windupnetval :='--'  ;
       select pt.id, pt.cp_id, pt.name, pt.product_no, pt.product_type into v_id ,v_cpid,v_name,v_productno,v_producttype
       from BUSI_PRODUCT pt where pt.product_no=v_xmdm;
       
       insert into BUSI_CLEAR_PRODUCT(id,cp_id,name,product_no,product_type,wind_up_date,wind_up_net_val,sync_date) 
       values(v_id ,v_cpid,v_name,v_productno,v_producttype,to_char(v_xmbh_qtime,'yyyymmdd'),v_windupnetval,to_char(sysdate,'yyyymmdd hh24:mi:ss'));

      
   end if;


end loop;

 close custinfo_cur;

v_msg :='同步清盘产品信息成功';
insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
commit;

EXCEPTION
    when others then
        if custinfo_cur%isopen then
            close custinfo_cur;
        end if;
        rollback;

        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm ||v_xmdm || v_xmbh_qtime || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_CLEAR_PRODUCT;
/

