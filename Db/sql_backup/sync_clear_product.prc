CREATE OR REPLACE PROCEDURE SMZJ.SYNC_CLEAR_PRODUCT
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
    v_job_name                   varchar2(100):= 'ͬ�����̲�Ʒ��Ϣ';



    v_xmdm                       varchar(20 char);               --��Ʒ����
    v_xmbh_qtime                date;            --��������
   -- v_count                      integer;  
    v_produc_count                      integer;                                      --�������¼����
    v_id                         BUSI_CLEAR_PRODUCT.id%type;               --��ƷID
    v_cpid                       BUSI_CLEAR_PRODUCT.cp_id%type;            --˽ļ��˾ID
    v_name                       BUSI_CLEAR_PRODUCT.name%type;             --��Ʒ����
    v_productno                  BUSI_CLEAR_PRODUCT.product_no%type;       --��Ʒ����
    v_producttype                BUSI_CLEAR_PRODUCT.product_type%type;     --��Ʒ����
    v_windupnetval              varchar(20 char);  --���̾�ֵ



    cursor custinfo_cur is select t.vc_xmdm, t.d_xmbh_qtime from tgyyzx.v_ysmzj_xmxx@yy_dblimk t where t.d_xmbh_qtime is not null and not exists(select a.product_no from BUSI_CLEAR_PRODUCT a where a.product_no=t.vc_xmdm);



begin        --ͬ�����̲�Ʒ��Ϣ��ʼ
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

v_msg :='ͬ�����̲�Ʒ��Ϣ�ɹ�';
insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
commit;

EXCEPTION
    when others then
        if custinfo_cur%isopen then
            close custinfo_cur;
        end if;
        rollback;

        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm ||v_xmdm || v_xmbh_qtime || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_CLEAR_PRODUCT;
/

