create or replace procedure smzj.SYNC_GSWJZ_INFO
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_GSWJZ_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ����ˮλ����ȫ��ͬ��
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-29
-- VERSION:
-- EDIT HISTORY:
-- 2015-12-09    ��չ��ˮλ��Ϣ
-- *************************************************************************
AS
    lastDay varchar2(8);           --��ǰ��һ��
    v_msg   varchar2(1000);
    v_job_name varchar2(100):= 'ͬ����ˮλ��Ϣ';
    v_count integer;
    v_sql varchar2(100);
begin
    v_sql:='truncate table t_gswjz_info';
    execute immediate v_sql;
   
    select count(*) into v_count from t_gswjz_info;
    if v_count = 0 then
        --execute immediate v_sql;
        /*
        insert into t_gswjz_info
        (sqdh,cpdm,djzh,khbh,
         qmfe,qrrq,dwjz,gzrq)
        select
        sqdh,cpdm,djzh,khbh,
        qmfe,qrrq,dwjz,gzrq
        from zsta.ut_sm_h_jsmxb@TA_DBLINK t;
        */
        insert into t_gswjz_info
        (YLSH,SQDH,QRLS,KHBH,CPDM,
         DJZH,QRRQ,GSWS,QMFE,HBJX,
         HCZJ,JJFB,LPFB,YZYK,FQZC,
         TGFY,GLFY,CWFY,KZFY,JQZJ,
         JXFY,ZCJZ,JDJZ,FZJZ,DWJZ,
         GZRQ,CYJG,JTBZ,KHSX,GFBZ,
         YFBZ,LGSW,LZCJ,LQMF,JDJE,
         JQJZ,XSRM,JSBZ)
        select
         YLSH,SQDH,QRLS,KHBH,CPDM,
         DJZH,QRRQ,GSWS,QMFE,HBJX,
         HCZJ,JJFB,LPFB,YZYK,FQZC,
         TGFY,GLFY,CWFY,KZFY,JQZJ,
         JXFY,ZCJZ,JDJZ,FZJZ,DWJZ,
         GZRQ,CYJG,JTBZ,KHSX,GFBZ,
         YFBZ,LGSW,LZCJ,LQMF,JDJE,
         JQJZ,XSRM,JSBZ
         from zsta.ut_sm_h_jsmxb@TA_DBLINK t;
        
    else --�Զ�ʱ��ֻ��������ͬ��
        select to_char(sysdate-1,'yyyyMMdd') into lastDay from dual;
        delete from t_gswjz_info t where t.gzrq = lastDay;
        insert into t_gswjz_info
        (YLSH,SQDH,QRLS,KHBH,CPDM,
         DJZH,QRRQ,GSWS,QMFE,HBJX,
         HCZJ,JJFB,LPFB,YZYK,FQZC,
         TGFY,GLFY,CWFY,KZFY,JQZJ,
         JXFY,ZCJZ,JDJZ,FZJZ,DWJZ,
         GZRQ,CYJG,JTBZ,KHSX,GFBZ,
         YFBZ,LGSW,LZCJ,LQMF,JDJE,
         JQJZ,XSRM,JSBZ)
        select
         YLSH,SQDH,QRLS,KHBH,CPDM,
         DJZH,QRRQ,GSWS,QMFE,HBJX,
         HCZJ,JJFB,LPFB,YZYK,FQZC,
         TGFY,GLFY,CWFY,KZFY,JQZJ,
         JXFY,ZCJZ,JDJZ,FZJZ,DWJZ,
         GZRQ,CYJG,JTBZ,KHSX,GFBZ,
         YFBZ,LGSW,LZCJ,LQMF,JDJE,
         JQJZ,XSRM,JSBZ
        from zsta.ut_sm_h_jsmxb@TA_DBLINK t where t.gzrq = lastDay ;
       
     
    end if;

    --ͬ��Ͷ����������֤������
    
        update t_gswjz_info t
       set ( CREDIT_NO,zjlx,khmc,zjhm) =
           (select bi.zjhm,bi.zjlx,bi.name,bi.zjhm
              from TA_ALL_user bi
             where t.djzh = bi.dzjh
               and rownum <= 1)
     where exists (select t.djzh from TA_ALL_user bi where t.djzh = bi.dzjh);
     
     
     update t_gswjz_info t
       set (khmc, zjhm,zjlx,CREDIT_NO) =
           (select bi.name, bi.zjhm,bi.zjlx,bi.zjhm
              from TA_ALL_user bi,TA_ALL_COMPANY c 
             where t.djzh = bi.dzjh and c.code=bi.jgbm and c.source='1'
               and rownum <= 1)
     where exists (select bi.dzjh   from TA_ALL_user bi,TA_ALL_COMPANY c 
             where t.djzh = bi.dzjh and c.code=bi.jgbm and c.source='1');
     
  
     --ֱ���ͻ�
     update t_gswjz_info t
       set (khmc, zjhm,zjlx) =
           (select bi.name, bi.credit_no,bi.credit_type
              from Busi_Investor_Credit bi
             where t.djzh = bi.regist_account 
               and rownum <= 1)
     where exists (select bi.regist_account from Busi_Investor_Credit  bi where t.djzh = bi.REGIST_ACCOUNT)
     and exists  (select cc.code from TA_ALL_COMPANY cc where t.xsrm=cc.code and cc.source='0') ;



    update t_gswjz_info t set (t.cp_id,t.pro_name,t.pro_id)=(   select p.cp_id,p.name,p.id from busi_product p where p.product_no=t.cpdm);

         update t_gswjz_info t set (t.insti_name,t.sourcetype)= (select p.name,p.source from TA_ALL_COMPANY p where t.XSRM = p.code)
           where  exists (select p.name from TA_ALL_COMPANY p where t.XSRM = p.code);

        update t_gswjz_info t set (t.qcfe)=
        ( select d.CONFIRM_SHARE from busi_share_detail d where  t.qrls=d.ID and t.cpdm=d.pt_no   );

        --ҵ����������� ��ѯ���������������
        delete t_gswjz_info info where
        exists(
               select * from   busi_product p where p.is_import_sales='0' and p.is_delete='0' and info.cpdm=p.product_no
        ) and info.sourcetype='1';


    v_msg :='ͬ���ɹ�';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
    commit;
EXCEPTION
    when others then
        rollback;
        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm;
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_GSWJZ_INFO;
/

