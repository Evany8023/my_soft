create or replace procedure smzj.SYNC_ACCT_INFO
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_ACCT_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ���˻���Ϣ
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
    v_job_name                   varchar2(100):= 'SYNC_ACCT_INFO';

    v_cust_count                 integer;                       --�ͻ�����
    v_cust_com_count             integer;                      --��˾�Ƿ����
    v_com_count             integer;                      --��˾�Ƿ����
    v_credit_id                  Busi_Investor_Credit.id%type;
    v_comp_id                    BUSI_INVESTOR_DETAIL.Company_Id%type;


    v_zjhm            Busi_Investor_Credit.Credit_No%type;      --֤������
    v_zjlx            Busi_Investor_Credit.Credit_Type%type;    --֤������
    v_jgbm            BUSI_COMPANY.Insti_Code%type;             --��������
    v_tzrxm           Busi_Investor_Credit.Name%type;           --Ͷ��������
    v_djzh            Busi_Investor_Credit.Regist_Account%type; --�Ǽ��˺�
    v_tzrlx           Busi_Investor_Credit.User_Type%type;      --Ͷ�������ͣ�1�����ˣ�2��������
    v_gdhm            BUSI_INVESTOR_DETAIL.PHONE%type;          --�̶�����
    v_sjhm            BUSI_INVESTOR_DETAIL.TELEPHONE%type;      --�ֻ���
    v_dzyj            BUSI_INVESTOR_DETAIL.EMAIL%type;          --����
    v_yzbm            BUSI_INVESTOR_DETAIL.Zip_Code%type;       --�ʱ�
    v_txdz            BUSI_INVESTOR_DETAIL.ADDRESS%type;        --��ַ
    v_czhm            BUSI_INVESTOR_DETAIL.FAX%type;            --����
    v_frdb            BUSI_INVESTOR_DETAIL.LEGAL_PERSON%type;   --���˴���
    v_jbrxm           BUSI_INVESTOR_DETAIL.HANDLE_PERSON%type;  --����������
    v_password        Busi_Investor_Credit.Password%type;        -- ����
    v_khbh        Busi_Investor_Credit.Custom_No%type;        -- ����
    --v_flag             varchar(20);
   -- v_detail_id        varchar(32);
   -- v_apply_no         varchar(32);
    cursor custinfo_cur is select t.djzh, t.khmc, t.zjhm, t.jgbm, t.tzrlx,
     t.gddh, t.sjhm, t.dzyj, t.yzbm, t.txdz, t.czhm, t.frdb, t.jbrmc ,t.zjlx,t.khbh from zsta.uv_xx_khxx_sm@TA_DBLINK t;

  -- cursor cust_khinfo is select c.regist_account,bc.insti_code from Busi_Investor_Credit c,busi_trading_confirm cc,busi_product p,Busi_Company bc   where c.id not in (
 --                         select d.credit_id from busi_investor_detail d
  --                        ) and c.regist_account is not null and c.regist_account=cc.regist_account and cc.pt_no=p.product_no and p.cp_id=bc.id
  --                        group by c.regist_account,bc.insti_code ;

begin        --ͬ���ͻ���Ϣ��ʼ
     execute immediate  'truncate table Busi_Ta_Inverstor';
     
     INSERT INTO busi_ta_inverstor(name,zjlx,zlhm,djzh,JGBM)
 select t.khmc,t.zjlx, t.zjhm,t.djzh,  t.jgbm from zsta.uv_xx_khxx_sm@TA_DBLINK t;
 
     open custinfo_cur; 
        loop
            fetch custinfo_cur into v_djzh, v_tzrxm, v_zjhm, v_jgbm, v_tzrlx,
               v_gdhm, v_sjhm, v_dzyj, v_yzbm, v_txdz, v_czhm, v_frdb, v_jbrxm, v_zjlx,v_khbh;
            if custinfo_cur%notfound then
               exit;
            end if;
             if v_tzrlx='1' then
               v_tzrlx:='2';
             else
                v_tzrlx:='1';
             end if;
            --BUSI Ͷ����֤����  BUSI_INVESTOR_CREDIT
            select count(*) into v_cust_count from Busi_Investor_Credit t where t.credit_no   = v_zjhm and t.credit_type = v_zjlx; --֤������
            v_password :=null;
            v_credit_id:= null;
            if v_cust_count = 0 then --�Ǵ��ڿͻ�
                select md5(substr(v_zjhm, length(v_zjhm) - 6 + 1, 6))  into v_password  from dual;
                select lower(SYS_GUID()) into v_credit_id  from dual;
                insert into BUSI_INVESTOR_CREDIT
                         ( id, user_type,name, credit_type, credit_no, regist_account, is_examine,examine_date,create_by, create_date,update_by,update_date, is_delete,password,CUSTOM_NO)
                         values (v_credit_id,v_tzrlx,v_tzrxm,v_zjlx, v_zjhm,v_djzh,'1', sysdate,'userjob',sysdate, 'userjob',sysdate, '0', v_password,v_khbh);
            elsif v_cust_count >1 then
                   v_msg := 'ͬ���ͻ���Ϣʱ�������ظ����û���' ||v_tzrxm || '��֤������:' || v_zjhm;
                    insert into t_fund_job_running_log (job_name, job_running_log) values (v_job_name, v_msg);
            else
                  update Busi_Investor_Credit t set t.regist_account=v_djzh,t.user_type=v_tzrlx,t.credit_no=v_zjhm,t.credit_type=v_zjlx where  t.credit_no   = v_zjhm  and t.credit_type = v_zjlx;
                  select id into v_credit_id from Busi_Investor_Credit t  where t.credit_no   = v_zjhm  and t.credit_type = v_zjlx; --֤������

            end if;


            --�鿴�Ƿ��������˾Busi_Credit_Company
         v_comp_id:=null;
          select count(1) into   v_com_count from BUSI_COMPANY t where t.insti_code = v_jgbm ;
          if  v_com_count  <1 then
               v_msg := 'ͬ���ͻ���Ϣʱ���Ҳ�����Ӧ�������룺' || v_jgbm || '��Ӧ�Ļ���˾';
               insert into t_fund_job_running_log (job_name, job_running_log) values (v_job_name, v_msg);
          elsif v_com_count=1 then
            select t.id into v_comp_id from BUSI_COMPANY t where t.insti_code = v_jgbm ;
          else
              v_msg := 'ͬ���ͻ���Ϣʱ�����������ظ���' || v_jgbm ;
               insert into t_fund_job_running_log (job_name, job_running_log) values (v_job_name, v_msg);
          end if;

            --����BUSI_INVESTOR_DETAIL��
            if v_credit_id is not null and v_comp_id is not null then
                 select count(1) into v_cust_com_count  from  BUSI_CREDIT_COMPANY t  where t.credit_id = v_credit_id and t.COMPANY_ID = v_comp_id;
                 if v_cust_com_count < 1 then
                     insert into BUSI_CREDIT_COMPANY(CREDIT_ID,COMPANY_ID) values(v_credit_id,v_comp_id);
                  end if;



            end if;
end loop;
close custinfo_cur;

-- �ύ����
/*
open cust_khinfo;
      loop
            fetch cust_khinfo into v_djzh, v_jgbm;
            if cust_khinfo%notfound then
               exit;
            end if;
      v_flag:='1' ;
     begin
        select t.DZJH, t.NAME, t.zjhm, t.tzrlx,t.gddh, t.sjhm, t.dzyj, t.yzbm, t.txdz, t.czhm, t.frdb, t.jbrmc ,t.zjlx,c.id
               into v_djzh, v_tzrxm, v_zjhm,  v_tzrlx,  v_gdhm, v_sjhm, v_dzyj, v_yzbm, v_txdz, v_czhm, v_frdb, v_jbrxm, v_zjlx,v_credit_id
         from ta_all_user t,busi_investor_credit c where t.dzjh=   v_djzh and c.credit_no=t.zjhm and c.credit_type=t.zjlx;
         select c.id into v_comp_id  from Busi_Company c where c.insti_code= v_jgbm;


      exception when no_data_found then
       v_flag:='0';
      end;
      select count(1) into v_cust_count from Busi_Investor_Credit c where c.credit_no=v_zjhm and c.credit_type=v_zjlx
                                         and c.id  in(select d.credit_id from busi_investor_detail d );

      if v_flag ='1' and v_cust_count < 1 then
           select sys_guid() into v_detail_id from dual;
           select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
           insert into busi_investor_detail(id,investor_type,HANDLE_PERSON,legal_person,name,create_by,busi_type,company_id,apply_no,create_date,credit_id,credit_type,credit_no,MANAGE_FEE_MARK,ACHIEVE_FEE_MARK,ZIP_CODE,ADDRESS,TELEPHONE,PHONE,EMAIL,REMARK,is_delete,fax,is_examine,examine_date,examine_by,regist_account,refrence)
           values(v_detail_id,v_tzrlx,v_jbrxm,v_frdb,v_tzrxm,'sync','001',v_comp_id,v_apply_no,sysdate,v_credit_id,v_zjlx,v_zjhm,'��','��',v_yzbm,v_txdz,v_gdhm,v_sjhm,v_dzyj,'','0',v_czhm,'1',sysdate,'sync',v_djzh,'4');



      end if;



 end loop;
close cust_khinfo;
*/
 execute immediate  'update Busi_Investor_Credit ic set ic.REGS=(
     select wmsys.wm_concat( distinct u.djzh )  from Busi_Ta_Inverstor u 
    where u.zlhm=ic.credit_no and u.zjlx=ic.credit_type 
   
 ) where exists(
    select u.djzh from Busi_Ta_Inverstor u 
    where u.zlhm=ic.credit_no and u.zjlx=ic.credit_type 
 )';

update Busi_Investor_Credit ic set ic.REGS=ic.regist_account where ic.regs is null;
 

v_msg :='ͬ���ɹ�';
 insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
  commit;

EXCEPTION
    when others then
        if custinfo_cur%isopen then
            close custinfo_cur;
        end if;
       --  if cust_khinfo%isopen then
       --     close cust_khinfo;
      --  end if;

        rollback;

        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_ACCT_INFO;
/

