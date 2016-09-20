create or replace procedure smzj.syn_old_system_data is
v_msg varchar2(4000);--返回信息
-- 公司 属性
v_audit_user t_fund_company.audit_user%type;
v_com_code t_fund_company.com_code%type;
v_com_name t_fund_company.com_name%type;
v_create_date t_fund_company.create_date%type;
v_create_user t_fund_company.create_user%type;
v_update_date t_fund_company.update_date%type;
v_job_log_name varchar2(20) := 'syn_old_system_data';
v_generate_id  varchar2(32 char);
v_com_id  varchar2(32 char);
v_sql  varchar2(1000 char);
v_count  integer;
v_m_count  integer;

  -- 产品
  v_fund_id               NUMBER(19) ;
  v_m_fund_id            varchar(32 char);
  v_fund_clrq            VARCHAR2(255 CHAR) ;
  v_fund_code             VARCHAR2(255 CHAR) ;
  v_fund_cpqx            VARCHAR2(255 CHAR);
  v_fund_jztbzq           NUMBER(10) ;
  v_fund_name               VARCHAR2(255 CHAR) ;
  v_fund_tgr              VARCHAR2(255 CHAR) ;
  v_fund_type             VARCHAR2(40 CHAR) ;
  v_fund_zytzfw           VARCHAR2(1024 CHAR) ;
  v_fund_zzddjg          VARCHAR2(255 CHAR) ;
  v_isvalid              NUMBER(1) ;
  v_ismfundcode        NUMBER(1) ;
  v_isclassify          NUMBER(1) ;
  v_isydyt             NUMBER(1) ;
  v_isreview          VARCHAR2(16 CHAR) ;
  v_fund_tzzjztbzq      NUMBER(10) ;
  v_isshowatpl             NUMBER(1) ;
  v_fund_mdm              VARCHAR2(16 CHAR) ;
  v_fund_manager_info     VARCHAR2(255 CHAR) ;
  v_fund_tzgw               VARCHAR2(255 CHAR);
  v_isshowtgjl             NUMBER(1) ;
  v_islskf                 NUMBER(1) ;
  v_fund_glrjztbzq         NUMBER(1) ;
  v_is_mocode_kfr_pl       NUMBER(1);
  v_is_open_fhfs           NUMBER(1) ;
  v_is_user_limit          NUMBER(1) ;
  v_is_gsw_fund            NUMBER(1) ;
  v_is_opend_day_fund      NUMBER(1) ;
  /**
  v_fund_state_code_manual varchar2(20 char);
  v_fund_state_manual      varchar2(40 char);
  v_fund_state_date        varchar2(8 char);
  v_is_opend_day           number(1) ;
  **/
  -- 证件号码
v_cust_id            number(19);
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
v_generate_fund_id  varchar2(32 char);
v_generate_cust_id  varchar2(32 char);
user_com_id  varchar2(32 char);

cursor comp_cur  is select t.audit_user,t.com_code,t.com_name,t.create_date,t.create_user,t.update_date ,t.id
    from t_fund_company@newone t
   where t.isvalid=1 and t.isreview=1 ;
fundinfo_cur    SYS_REFCURSOR;
com_user_cur    SYS_REFCURSOR;
cursor cust_cur    is select t.id, t.idcard,t.pass_word,t.user_name,t.djzh,t.khbh,t.is_activate,t.is_delete ,t.is_resetpw,t.idtypecode
    from t_fund_cust@newone t
   where t.isvalid=1 and t.idtypecode is not null ;

begin
  open comp_cur ;
  loop
    fetch comp_cur into v_audit_user ,v_com_code,v_com_name,v_create_date,v_create_user,v_update_date,v_com_id;

    if comp_cur%notfound then
      exit;
    end if;

    select count(1) into v_count from  busi_company t where t.INSTI_CODE=v_com_code;
    if v_count < 1 then
            select lower(SYS_GUID()) into v_generate_id  from dual;
            insert into   busi_company (id,CP_NAME,INSTI_CODE,IS_EXAMINE,EXAMINE_BY,EXAMINE_DATE,CREATE_BY,CREATE_DATE,IS_DELETE,UPDATE_DATE)
            values(v_generate_id,v_com_name,v_com_code,'1','oldsys',sysdate,v_create_user,v_create_date,'0',v_update_date );
      else
         update busi_company t set t.cp_name=v_com_name where t.insti_code=v_com_code;
         select t.id,t.cp_name into v_generate_id,v_com_name from  busi_company t where t.INSTI_CODE=v_com_code;
    end if;

end loop;
close comp_cur;
commit;

--证件号码。
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

-- 开户，银行账号，交易申请同步。



  v_msg:='老数据同步成功！';
  insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);

 commit;

exception
     when others then
         if fundinfo_cur%isopen then
            close fundinfo_cur;
        end if;

         if cust_cur%isopen then
            close cust_cur;
        end if;
         if comp_cur%isopen then
            close comp_cur;
        end if;

     rollback;
     DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
     DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
     v_msg:='老数据同步'||sqlcode||':'||sqlerrm  ||dbms_utility.format_error_stack || v_cust_idcard;
     insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
     commit;

end syn_old_system_data;
/

