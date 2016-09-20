create or replace procedure smzj.syn_old_system_10d_data is
v_msg varchar2(4000);--返回信息
v_job_log_name varchar2(60) :='syn_old_system_10d_data';

v_bzxx             varchar(1000 char);--备注
v_create_date     TIMESTAMP(6);--创建时间
v_create_user      varchar(100 char);--创建人
v_acc_khhszs       VARCHAR2(255 CHAR);
v_acc_khmc         VARCHAR2(255 CHAR);
v_acc_khhszsf     VARCHAR2(255 CHAR);
v_acc_khyh         VARCHAR2(255 CHAR);
v_acc_sqdh        VARCHAR2(255 CHAR);
v_acc_sqrq         VARCHAR2(255 CHAR);
v_acc_sqsj        VARCHAR2(255 CHAR);
v_acc_yhzh        VARCHAR2(255 CHAR);
v_acc_khhmc        VARCHAR2(255 CHAR);
v_acc_lhh          VARCHAR2(255 CHAR);
v_acc_xssdm        VARCHAR2(255 CHAR);
v_acc_yhbh        VARCHAR2(255 CHAR);
v_acc_yhhm         VARCHAR2(255 CHAR);
v_acc_yhbh_code   VARCHAR2(255 CHAR);
v_acc_sfcode       VARCHAR2(255 CHAR);
v_acc_cscode       VARCHAR2(255 CHAR);
v_is_fhsh_account  VARCHAR2(255 CHAR);
v_idcard           VARCHAR2(255 CHAR);
v_idtypecode      VARCHAR2(255 CHAR);
v_djzh            VARCHAR2(255 CHAR);
v_fund_id               NUMBER(19) ;
  /**
  v_fund_state_code_manual varchar2(20 char);
  v_fund_state_manual      varchar2(40 char);
  v_fund_state_date        varchar2(8 char);
  v_is_opend_day           number(1) ;
  **/
  -- 证件号码
v_cust_idcard        varchar2(50 char);
v_cust_pass_word     varchar2(50 char);
v_cust_user_name     varchar2(60 char);
v_cust_djzh          varchar2(255 char);
v_cust_khbh          varchar2(255 char);
v_cust_idtypecode    varchar2(20 char);
v_cust_is_activate   number(1);
v_cust_is_resetpw    number(1) ;
v_cust_is_delete     number(1) ;
v_cust_user_type  varchar2(20 char);
v_generate_cust_id  varchar2(32 char);

v_buss_type       VARCHAR2(255 CHAR);    --开户类型           --开户备注
v_glfbz            VARCHAR2(255 CHAR);
v_jggrlx           VARCHAR2(255 CHAR);
v_sqdh              VARCHAR2(255 CHAR);
v_sqrq            VARCHAR2(255 CHAR);
v_yjfbz           VARCHAR2(255 CHAR);
v_frdb            VARCHAR2(255 CHAR);   --法人代表
v_hhrsx           VARCHAR2(255 CHAR);
v_jbrxm          VARCHAR2(255 CHAR);
v_lxrxm            VARCHAR2(255 CHAR);
v_buss_type_code   VARCHAR2(255 CHAR);
v_jggrlxcode      VARCHAR2(255 CHAR);
v_jgbm          VARCHAR2(255 CHAR);             --机构编码
v_tzrxm           VARCHAR2(255 CHAR);           --投资人姓名
v_gdhm             VARCHAR2(255 CHAR);          --固定号码
v_sjhm             VARCHAR2(255 CHAR);      --手机号
v_dzyj             VARCHAR2(255 CHAR);          --邮箱
v_yzbm             VARCHAR2(255 CHAR);       --邮编
v_txdz             VARCHAR2(255 CHAR);        --地址
v_hkbh             VARCHAR2(255 CHAR);
v_credit_card      VARCHAR2(50 CHAR);
v_credit_type_code VARCHAR2(20 CHAR);
v_count  integer;
v_kh_id varchar(16 char);  --开户id


v_trade_fhbl     VARCHAR2(255 CHAR);--创建时间
v_trade_fhfs    VARCHAR2(255 CHAR);--创建人
v_trade_jesh      VARCHAR2(255 CHAR);
v_trade_sqdh        VARCHAR2(255 CHAR);
v_trade_sqfe      VARCHAR2(255 CHAR);
v_trade_sqje         VARCHAR2(255 CHAR);
v_trade_sqrq         VARCHAR2(255 CHAR);
v_trade_sqsj      VARCHAR2(255 CHAR);
v_trade_sxfy        VARCHAR2(255 CHAR);
v_trade_type         VARCHAR2(255 CHAR);
v_trade_ysqh       VARCHAR2(255 CHAR);
v_trade_ysqs          VARCHAR2(255 CHAR);
v_trade_zdsh       VARCHAR2(255 CHAR);
v_trade_fhfs_code    VARCHAR2(255 CHAR);
v_trade_jesh_code      VARCHAR2(255 CHAR);
v_trade_type_code      VARCHAR2(255 CHAR);
v_jy_id varchar(16 char);  --交易id
v_import_day date;

v_cust_id varchar(35 char);
v_generate_id  varchar(35 char);
v_product_id  varchar(35 char);
v_comid varchar(35 char);
v_m_count  integer;
v_yhzh_count  integer;
v_yh_id varchar(16 char);  --开户id
v_dou_count  integer;
v_bind_date date;
v_OLD_MANAGER integer;
V_sql varchar(1000 char);
com_user_cur    SYS_REFCURSOR;
user_com_id  varchar2(32 char);
v_product_code  varchar(35 char);

cursor account_cur    is select t.id, t.acc_bzxx,t.acc_khhszs,t.acc_khhszsf,t.acc_khyh,t.acc_sqdh,t.acc_sqrq,t.acc_sqsj,t.acc_yhzh,t.create_date,t.fund_id
    ,t.acc_khhmc,t.acc_lhh,t.acc_xssdm,t.acc_yhbh,t.acc_yhhm,t.create_user,t.acc_yhbh_code,t.acc_sfcode,t.acc_cscode,t.is_fhsh_account,
    c.idcard,c.idtypecode,c.djzh ,t.acc_khmc
   from t_fund_account@newone t, t_fund_cust@newone c
   where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1 and  t.acc_sqrq >=to_char(sysdate-10,'yyyyMMdd')  ;

cursor khsq_cur    is select t.id, t.buss_type,t.bzxx,t.create_date,t.create_user,t.glfbz,t.jggrlx,t.sqdh,t.sqrq,t.yjfbz,t.frdbxm,t.hhrsx,t.jbrxm,
                             t.lxrxm,t.tzrxm,t.buss_type_code,t.jggrlxcode,t.jgbm,c.gddh,c.email,c.mobile,c.post_num,c.txdz,c.khbh ,c.id ,c.idcard,c.idtypecode,c.djzh
    from t_fund_khsq@newone t,t_fund_cust@newone  c
   where t.cust_id=c.id and t.is_delete=0 and t.sqrq >=to_char(sysdate-10,'yyyyMMdd') ;

cursor cust_cur    is select t.id, t.idcard,t.pass_word,t.user_name,t.djzh,t.khbh,t.is_activate,t.is_delete ,t.is_resetpw,t.idtypecode
    from t_fund_cust@newone t
   where t.isvalid=1 and t.idtypecode is not null and t.create_date >=(trunc(sysdate-20)) ;

cursor jy_cur is select t.id, t.create_date,t.trade_bzxx,t.trade_fhbl,t.trade_fhfs,t.trade_jesh,t.trade_sqdh,t.trade_sqfe,t.trade_sqje,t.trade_sqrq,t.trade_sqsj
    ,t.trade_sxfy,t.trade_type,t.trade_ysqh,t.trade_ysqs,t.trade_zdsh,t.fund_id,t.create_user,t.trade_fhfs_code,t.trade_jesh_code,t.trade_type_code,t.jgbm ,
    c.idcard,c.idtypecode,c.djzh
   from t_fund_trade@newone t,t_fund_cust@newone c
   where t.cust_id=c.id and t.is_delete=0 and t.isvalid=1   and t.trade_sqrq>=to_char(sysdate-10,'yyyyMMdd');

begin

-- 客户同步
open cust_cur ;
loop
  fetch cust_cur into    v_cust_id,  v_cust_idcard,v_cust_pass_word,v_cust_user_name,v_cust_djzh,v_cust_khbh,v_cust_is_activate,v_cust_is_delete,v_cust_is_resetpw,v_cust_idtypecode;
       if cust_cur%notfound then
      exit;
    end if;
    v_cust_user_type:=2;
    if instr(v_cust_idtypecode ,'0',1,1) = 1 then
       v_cust_user_type:=1;
     end if;


     select count(1) into v_count from  busi_investor_credit t where t.credit_no=v_cust_idcard and t.credit_type =v_cust_idtypecode;
    if v_count < 1 then
            select lower(SYS_GUID()) into v_generate_cust_id  from dual;
            insert into  busi_investor_credit(id,credit_type,credit_no,is_examine,examine_by,examine_date,create_by,create_date,is_delete,name,
                user_type,regist_account,password,is_active,custom_no,refrence)

                values(v_generate_cust_id,v_cust_idtypecode,v_cust_idcard,1,'oldsys',sysdate,'oldsys',sysdate,0,v_cust_user_name,v_cust_user_type,v_cust_djzh,v_cust_pass_word,
                v_cust_is_activate,v_cust_khbh,4);
      elsif v_count> 0 then
         update busi_investor_credit t set t.custom_no=custom_no,t.name=v_cust_user_name,t.regist_account=v_cust_djzh  where t.credit_no=v_cust_idcard and t.credit_type =v_cust_idtypecode;
         update busi_investor_credit t set t.is_active= v_cust_is_activate where t.credit_no=v_cust_idcard and t.credit_type =v_cust_idtypecode and t.is_active=0;
         select t.id into v_generate_cust_id from  busi_investor_credit t where t.credit_no=v_cust_idcard and t.credit_type =v_cust_idtypecode;
      end if;

    v_sql:=' select  t.id   from t_fundcust_company@newone  cc  ,t_fund_company@newone  c, busi_company  t where  cc.comp_id=c.id and t.insti_code=c.com_code and cc.user_id='||v_cust_id ;
   open  com_user_cur for v_sql;
   loop
    fetch com_user_cur into user_com_id;
     if com_user_cur%notfound then
      exit;
    end if;
      select count(1) into v_count from  busi_credit_company cc where cc.credit_id=v_generate_cust_id and cc.company_id=user_com_id;
      if v_count < 1  and v_generate_cust_id is not null  then
        insert into  busi_credit_company(credit_id,company_id) values(v_generate_cust_id,user_com_id);
      end if;


    end loop;
    close com_user_cur;


end loop;
close    cust_cur;


-- 开户
open khsq_cur ;
loop
  fetch khsq_cur into v_kh_id, v_buss_type,v_bzxx, v_create_date,v_create_user,v_glfbz,v_jggrlx,v_sqdh,v_sqrq,v_yjfbz,v_frdb,v_hhrsx,v_jbrxm,v_lxrxm,v_tzrxm, v_buss_type_code,v_jggrlxcode
  ,v_jgbm,v_gdhm,v_dzyj,v_sjhm,v_yzbm,v_txdz,v_hkbh,v_cust_id,v_credit_card,v_credit_type_code,v_djzh;
       if khsq_cur%notfound then
          exit;
       end if;
                select count(1) into v_OLD_MANAGER from  t_FUND_OLD_MANAGER m where  m.fundcode=v_jgbm;
      if v_OLD_MANAGER < 1 then
                 v_cust_id:=null;
                select count(1) into v_count from busi_investor_credit c where c.credit_no=v_credit_card and c.credit_type=v_credit_type_code;
                if v_count =1 then
                   select c.id into v_cust_id from busi_investor_credit c where c.credit_no=v_credit_card and c.credit_type=v_credit_type_code;
                end if;

                select count(1) into v_m_count from busi_company  c where c.insti_code=v_jgbm;
                if v_m_count = 1 then
                  select c.id into v_comid from busi_company  c where c.insti_code=v_jgbm;
                end if;

                v_cust_user_type:=null;
                if instr(v_credit_type_code ,'0',1,1) = 1 then
                   v_cust_user_type:=1;
                elsif instr(v_credit_type_code ,'1',1,1) = 1 then
                  v_cust_user_type:=2;
                 end if;

                 select count(*) into v_dou_count from busi_investor_detail t where t.old_sys_id= v_kh_id;

                if v_cust_id is not null and v_comid is not null and v_dou_count< 1 then

                    select lower(SYS_GUID()) into v_generate_id  from dual;
                                insert into busi_investor_detail(id,company_id,credit_id,phone,telephone,email,zip_code,address,name,remark,create_by,create_date
                               ,is_delete,legal_person,handle_person,is_examine,examine_date,investor_type,credit_type,credit_no,regist_account,apply_no,busi_type,link_man
                               ,partner_attr,manage_fee_mark,achieve_fee_mark,refrence,old_sys_id)

                                values(v_generate_id,v_comid,v_cust_id,v_sjhm,v_gdhm,v_dzyj,v_yzbm,v_txdz,v_tzrxm,v_bzxx,v_create_user,to_date(v_sqrq,'yyyymmdd')
                                ,'0',v_frdb,v_jbrxm,'1',to_date(v_sqrq,'yyyymmdd'), v_cust_user_type,v_credit_type_code,v_credit_card,v_djzh,v_sqdh,v_buss_type_code,v_lxrxm
                                ,v_hhrsx,v_glfbz,v_yjfbz,'4',v_kh_id);

                 elsif       v_dou_count> 0 then

                 update    busi_investor_detail t set t.company_id=v_comid ,t.credit_id=v_cust_id,t.phone=v_sjhm,t.telephone=v_gdhm,
                 t.email=v_dzyj,t.zip_code=v_yzbm,t.address=v_txdz,t.name=v_tzrxm,t.remark=v_bzxx,t.legal_person=v_frdb,t.handle_person=v_jbrxm,
                 t.investor_type=v_cust_user_type,t.credit_type=v_credit_type_code,t.credit_no=v_credit_card ,t.regist_account=v_djzh,t.apply_no=v_sqdh,
                 t.busi_type=v_buss_type_code,t.link_man=v_lxrxm,t.partner_attr=v_hhrsx,t.manage_fee_mark=v_glfbz,t.achieve_fee_mark=v_yjfbz
                 where t.old_sys_id=v_kh_id;

                end if;

   end if;

end loop;
close    khsq_cur;

--银行账号
open account_cur ;
loop
  fetch account_cur into v_yh_id, v_bzxx,v_acc_khhszs,v_acc_khhszsf,v_acc_khyh,v_acc_sqdh,v_acc_sqrq,v_acc_sqsj,v_acc_yhzh,v_create_date,v_fund_id,
                         v_acc_khhmc,v_acc_lhh,v_acc_xssdm,v_acc_yhbh,v_acc_yhhm,v_create_user,v_acc_yhbh_code,v_acc_sfcode,v_acc_cscode,v_is_fhsh_account,
                         v_idcard,v_idtypecode,v_djzh,v_acc_khmc;
       if account_cur%notfound then
          exit;
       end if;

        select count(1) into v_OLD_MANAGER from  t_FUND_OLD_MANAGER m where  m.fundcode=v_acc_xssdm;
      if v_OLD_MANAGER < 1 then

                  v_cust_id:=null;
                select count(1) into v_count from busi_investor_credit c where c.credit_no=v_idcard and c.credit_type=v_idtypecode;
                if v_count >0 then
                   select c.id into v_cust_id from busi_investor_credit c where c.credit_no=v_idcard and c.credit_type=v_idtypecode;
                end if;

                select count(1) into v_m_count from busi_company  c where c.insti_code=v_acc_xssdm;
                if v_m_count> 0 then
                  select c.id into v_comid from busi_company  c where c.insti_code=v_acc_xssdm;
                end if;

                select count(1) into v_yhzh_count from busi_product t ,t_fund_info@newone info where info.fund_code=t.product_no and info.id=v_fund_id;
                if v_yhzh_count =1 then
                select t.id into  v_product_id   from busi_product t ,t_fund_info@newone info where info.fund_code=t.product_no and info.id=v_fund_id;
                end if;

                select count(*) into v_dou_count from busi_bind_bank_card t where t.old_sys_id= v_yh_id;
                v_bind_date:=to_date(v_acc_sqrq ||' ' ||v_acc_sqsj,'yyyyMMdd hh24:mi:ss') ;
                if v_cust_id is not null and v_comid is not null and v_product_id is not null and v_dou_count < 1 then
                                 select lower(SYS_GUID()) into v_generate_id  from dual;



                          insert into busi_bind_bank_card(id,credit_id,user_name,bank_no,bank_name,open_bank_name,province_id,province_name,city_id,city_name,bind_date
                            ,is_examine,examine_by,examine_date,create_by,create_date,is_delete,link_bank_no,account_no,remark,is_back_account,product_id,company_id,apply_date,old_sys_id,apply_no)

                            values(v_generate_id,v_cust_id,v_acc_khmc,v_acc_yhbh_code,v_acc_yhbh,v_acc_khhmc,v_acc_sfcode,v_acc_khhszsf,v_acc_cscode,v_acc_khhszs,v_bind_date
                            ,'1','oldysys',sysdate,v_create_user,v_bind_date ,'0',v_acc_lhh,v_acc_yhzh,v_bzxx,v_is_fhsh_account,v_product_id,v_comid,v_acc_sqrq ,v_yh_id,v_acc_sqdh);

                  elsif v_dou_count> 0 and  v_yh_id is not null then

                  update busi_bind_bank_card t set t.credit_id=v_cust_id,t.user_name=v_acc_khmc,t.bank_no=v_acc_yhbh_code,t.bank_name=v_acc_yhbh
                  ,t.open_bank_name=v_acc_khhmc,t.province_id=v_acc_sfcode,t.province_name=v_acc_khhszsf,t.city_id=v_acc_cscode,t.city_name=v_acc_khhszs,t.link_bank_no=v_acc_lhh
                  ,t.account_no=v_acc_yhzh,t.remark=v_bzxx,t.is_back_account=v_is_fhsh_account,t.product_id=v_product_id,t.company_id=v_comid,t.apply_date=v_acc_sqrq,t.apply_no=v_acc_sqdh
                  ,t.create_date=v_bind_date,t.bind_date=v_bind_date
                  where t.old_sys_id=v_yh_id;
                  end if;




         end if;



end loop;
close    account_cur;



-- 开户，银行账号，交易申请同步。

  delete from Busi_Bind_Bank_Card cc where cc.old_sys_id in(  select id from (
           select c.old_sys_id as id from  Busi_Bind_Bank_Card c  where c.old_sys_id is not null
            minus
           select   to_char(n.id) as   from t_Fund_Account@newone n where n.is_delete='0'
       )
 );

delete from Busi_Bind_Bank_Card cc where cc.old_sys_id in(  select   to_char(n.id) as   from t_Fund_Account@newone n where n.is_delete='1' );

-- 交易
open jy_cur ;
loop
  fetch jy_cur into v_jy_id, v_create_date,v_bzxx,v_trade_fhbl,v_trade_fhfs,v_trade_jesh,v_trade_sqdh,v_trade_sqfe,v_trade_sqje,v_trade_sqrq,v_trade_sqsj,
                v_trade_sxfy,   v_trade_type,  v_trade_ysqh,  v_trade_ysqs, v_trade_zdsh, v_fund_id,v_create_user,v_trade_fhfs_code,v_trade_jesh_code,v_trade_type_code,v_jgbm,
                v_idcard,v_idtypecode,v_djzh;
       if jy_cur%notfound then
          exit;
       end if;

      select count(1) into v_OLD_MANAGER from  t_FUND_OLD_MANAGER m where  m.fundcode=v_jgbm;
      if v_OLD_MANAGER < 1 then

            select to_date(v_trade_sqrq ||v_trade_sqsj ,'yyyyMMddHH24:MI:SS')  into v_import_day from dual;
              v_cust_id:=null;
            select count(1) into v_count from busi_investor_credit c where c.credit_no=v_idcard and c.credit_type=v_idtypecode;
            if v_count >0 then
               select c.id into v_cust_id from busi_investor_credit c where c.credit_no=v_idcard and c.credit_type=v_idtypecode;
            end if;

            select count(1) into v_m_count from busi_company  c where c.insti_code=v_jgbm;
            if v_m_count> 0 then
              select c.id into v_comid from busi_company  c where c.insti_code=v_jgbm;
            end if;

            select count(1) into v_yhzh_count from busi_product t ,t_fund_info@newone info where info.fund_code=t.product_no and info.id=v_fund_id;
            if v_yhzh_count =1 then
               select t.id,t.product_no into  v_product_id ,v_product_code  from busi_product t ,t_fund_info@newone info where info.fund_code=t.product_no and info.id=v_fund_id;
            end if;

            v_trade_sqje:=replace(v_trade_sqje,',','');
            if isnumeric(v_trade_sqje)=0 then
              v_trade_sqje:=null;
            end if;

             select count(*) into v_dou_count from BUSI_SHEET t where t.old_sys_id= v_jy_id;

            if v_cust_id is not null and v_comid is not null and v_product_id is not null and v_dou_count < 1 then


                      select lower(SYS_GUID()) into v_generate_id  from dual;
                      insert into BUSI_SHEET(id,sheet_no,pt_id,pt_no,dt_id,bank_card_id,sheet_create_time,amount,manager_contract_status,investor_contract_status,trustee_contract_status
                      ,fund_is_receive,investor_message,status,is_examine,examine_by,examine_date,create_by,create_date,business_type,company_id,credit_id,manager_fund_confirm,remark
                      ,apply_amount,apply_share,bonus_way,bonus_rate,procedure_fee,design_redeem,original_apply_no,huge_sum_redeem,original_apply_count,OLD_SYS_ID)

                      values(v_generate_id,v_trade_sqdh,v_product_id,v_product_code,null,null,v_import_day,to_number(v_trade_sqje,'99999999999999999.99'),'1', '1','1',
                      '1',null, '1','1','oldsys',sysdate,v_create_user,v_import_day,v_trade_type_code,v_comid,v_cust_id,'1',v_bzxx,
                     v_trade_sqje ,v_trade_sqfe,v_trade_fhfs,v_trade_fhbl,v_trade_sxfy,v_trade_zdsh,v_trade_ysqh,v_trade_jesh,v_trade_ysqs,v_jy_id);

              elsif v_dou_count> 0 then

              update BUSI_SHEET t set t.sheet_no=v_trade_sqdh ,t.pt_id=v_product_id,t.pt_no=v_product_code,t.sheet_create_time=v_import_day,
              t.amount=to_number(v_trade_sqje,'99999999999999999.99'),t.business_type=v_trade_type_code,t.create_date=v_import_day,t.company_id=v_comid,
              t.credit_id=v_cust_id,t.apply_amount=v_trade_sqje,t.apply_share=v_trade_sqfe,t.bonus_way=v_trade_fhfs,t.bonus_rate=v_trade_fhbl,
              t.procedure_fee=v_trade_sxfy,t.design_redeem=v_trade_zdsh,t.original_apply_no=v_trade_ysqh,t.huge_sum_redeem=v_trade_jesh,t.original_apply_count=v_trade_ysqs
              where t.old_sys_id=v_jy_id;



            end if;


      end if;


end loop;
close    jy_cur;

delete from busi_sheet st where st.old_sys_id in ( select t.old_sys_id from Busi_Sheet t where t.old_sys_id is not null  and t.sheet_create_time > (sysdate -10 )
and  not exists (select tr.id from t_Fund_Trade@newone tr where tr.id=t.old_sys_id ) ) ;


v_msg:='老数据同步成功';
  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
 commit;

exception
     when others then
         if account_cur%isopen then
            close account_cur;
        end if;

     rollback;
     DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
     DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
     v_msg:='老数据同步'||sqlcode||':'||sqlerrm  ||dbms_utility.format_error_stack || DBMS_UTILITY.format_error_backtrace ;
     insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
     commit;

end syn_old_system_10d_data;
/

