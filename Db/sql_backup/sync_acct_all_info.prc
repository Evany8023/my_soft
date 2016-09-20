CREATE OR REPLACE PROCEDURE SMZJ.SYNC_ACCT_ALL_INFO
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_ACCT_ALL_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ��ȫ������ֱ���Ŀͻ�
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
-- AUTHOR:       luoyuan
-- CREATE DATE:  2015-07-28
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
is
    v_msg                        varchar2(1000);
    v_job_name                   varchar2(100):= 'ͬ��TA�˻���Ϣ';


begin        --ͬ���ͻ���Ϣ��ʼ
   delete from ta_all_user;
   insert into ta_all_user(id,name,dzjh,zjhm,zjlx,khbm,gddh,sjhm,dzyj,yzbm,txdz,czhm,frdb,tzrlx,jbrmc,JGBM) 
           select  id_seq.nextval, m.khmc,m.djzh,m.zjhm,m.zjlx,m.khbh,m.gddh,m.sjhm,m.dzyj,m.yzbm,m.txdz,m.czhm,m.frdb,m.tzrlx,m.jbrmc,m.jgbm  from 
   ( select t.djzh, t.khmc, t.zjhm, t.jgbm, case t.tzrlx when '1' then '2' else '1' end tzrlx,t.khbh,
              t.gddh, t.sjhm, t.dzyj, t.yzbm, t.txdz, t.czhm, t.frdb, t.jbrmc ,t.zjlx
              from zsta.uv_xx_khxx_all@TA_DBLINK  t
   )m;
     
   insert into ta_all_user(id,name,dzjh,zjhm,zjlx,gddh,sjhm,dzyj,yzbm,txdz,type)       
   (select id_seq.nextval,t.investorname, j.taaccountid ,t.certificateno ,case t.invtp when '1' then '0' when '0' then '1' end || t.certificatetype as zjlx,
       t.telno,  t.mobiletelno,   t.emailaddress,  t.postcode, t.address ,'D'
  from zsta.acct_cust@ta_dblink t, zsta.hc_acct_fund@ta_dblink j
 where t.custno = j.custno );


delete from TA_ALL_COMPANY;
insert into TA_ALL_COMPANY(NAME,Code,SOURCE) select   t.distributorname,t.distributorcode ,
        CASE   lower(t.sywj_kzm)
        WHEN '.xls' THEN '0'
        ELSE '1' END
 from zsta.distributor@TA_DBLINK  t where t.distributorcode <> '802' ;

v_msg :='ͬ��TA�ɹ�';
 insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
commit;

EXCEPTION
    when others then
 
        rollback;

        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_ACCT_ALL_INFO;
/

