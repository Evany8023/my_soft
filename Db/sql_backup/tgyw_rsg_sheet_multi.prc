create or replace procedure smzj.tgyw_rsg_sheet_multi(
                                                      p_company_id in varchar2,
                                                      p_product_id in varchar2,
                                                      p_batchId in varchar2,
                                                      p_create_by in varchar2,
                                                      p_isMgr in varchar2,
                                                      p_mgrId in varchar2,
                                                      c_result out sys_refcursor) is

---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_rsg_sheet
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       刘石磊
-- DESCRIPTION:  批量导入认/申购订单
-- CREATE DATE:  2016-06-16
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
	
  v_job_name varchar2(100) :='tgyw_rsg_sheet';
  v_count integer;--记录已经生成数据条数
  v_limit_count integer;--记录产品是否有限制
  v_trade_count integer;--记录已经生成数据条数
  v_bank_accunt_no_count busi_sale_data.bank_accunt_no%type;--记录银行账号
  v_kh_count integer; --是否存在客户表t_fund_cust中
  v_khsq_count integer; --是否存在客户表t_fund_khsq中
  v_fundcomp_count integer;--是否关联基金公司
  v_msg varchar2(6000 char);--返回信息
  v_flag integer :=0;--标志本地证件号码对应的名称与TA的名称是否一致
  v_apply_date varchar2(20);
  v_legal_person busi_sale_data.legal_person %type;--法人代表姓名
  v_handel_person busi_sale_data.handel_person%type;--经办人姓名
  v_product_id varchar2(50);
  v_applay_date varchar2(10);
  v_bank_no busi_sale_data.bank_no%type;  --银行编号
  v_bank_name busi_sale_data.bank_name%type; --银行名称
  v_open_bank_name busi_sale_data.open_bank_name%type;--开户行名称
  v_rgje busi_sale_data.amount%type;--认购金额

  v_province_code busi_region.id%type;--省份代码
  v_city_code busi_region.id%type;-- 城市代码
  v_province_name busi_sale_data.province_name%type;--省份
  v_province_name_db busi_sale_data.province_name%type;--省份
  v_city_name busi_sale_data.city_name%type; --城市
  v_city_name_db busi_sale_data.city_name%type; --城市
  v_investor_type busi_sale_data.investor_type%type;--个人机构
  v_user_type CHAR(1);
  v_bank_card_id  VARCHAR2(32); -- 银行卡ID
  v_bank_account_name  busi_sale_data.bank_account_name%type; --银行户名
  v_bank_accunt_no  busi_sale_data.bank_accunt_no%type;--银行账号
  v_credit_no busi_sale_data.credit_no%type;--证件号码

  v_investor_name busi_sale_data.investor_name%type;--投资者姓名
  v_tab_id busi_sale_data.id%type;--临时表id

  v_credit_id busi_investor_credit.id%type; --证件ID
  v_khsqid busi_investor_detail.id%type;--开户申请表ID
  v_table_id varchar2(32) ;--表ID
  v_publish_status busi_product.publish_status%type;--基金状态
  v_busi_type varchar2(50);--认购类型
  v_is_limit_buy  busi_product.is_limit_buy%type;
  v_product_no varchar2(50);--基金代码
  v_apply_no busi_sheet.sheet_no%type;--申请单号
  v_busi_type_code varchar2(30);--业务类型
  v_custom_no varchar2(50 char);--客户编号
  v_product_name  varchar2(80 char); -- 产品名称
  v_hasimportdata integer :=1;--判断是否有导入数据
 -- v_ex_rgje varchar2(50 char)  ;--金额扩大10000倍
  v_investor_name_ta varchar2(50 char);--ta投资者姓名
  v_rg_je_ta  varchar2(50 char); --ta最低金额 字符型
  v_sh_je_ta varchar2(50 char); --ta最低金额 字符型
  v_rsh_je_ta varchar2(50 char); --ta最低金额 字符型
  v_rgje_ta number; --ta认购金额
  v_sg_rgje_ta number; --ta认购金额
  v_rgje_number number; --认购金额 number格式
  v_is_back_account char(1); --是否赎回分红账号
  v_credit_type_code  varchar2(50);--证件类型编码
  v_pt_status_count number; --是否有基金开放日
  v_start_price  VARCHAR2(128); --认申购起点
  v_current_date date; --当前时间
 v_buy_count number; --购买次数
   v_son_buy_monther varchar2(50 char); --子买母返回值
   v_sql_data                   varchar2(2014);                              --数据集SQL
  v_sql_check                  varchar2(2014);                              --校验SQL
  v_sql_count                   varchar2(2014);  
  v_sql_count2                  varchar2(2014);                            
  type myrefcur is ref cursor;
  data_cur_check myrefcur;
  data_cur myrefcur;
  pro_group_check myrefcur;
begin
  v_flag:=0;
     declare
     v_curdate_str varchar2(10);
     begin
       --参数错误校验
    select to_char(sysdate,'yyyyMMdd') into v_curdate_str from dual;
   
    v_sql_count:='select count(1) from  busi_sale_data t  where t.status = 0  and t.company_id ='''||p_company_id ||'''and t.batch_number_id='''||p_batchid||'''';
    --分组后的产品
    v_sql_count2:='select count(1) from (select t.product_id from busi_sale_data t  where t.COMPANY_ID='''||p_company_id||''' and to_char(t.APPLY_DATE,''yyyyMMdd'') >='''|| v_curdate_str ||''' and t.status=0 and t.batch_number_id='''||p_batchid||'''';
    --当为二级管理员的时候 需要关联管理人员产品表busi_product_authorization
    if p_isMgr=0 and p_mgrId is not null then
      v_sql_count:=v_sql_count||' and exists (select 1 from busi_product_authorization a where  a.PRODUCT_ID=t.PRODUCT_ID and a.MGR_ID='''||p_mgrId||''')';
      v_sql_count2:=v_sql_count2||' and exists (select 1 from busi_product_authorization a where  a.PRODUCT_ID=t.PRODUCT_ID and a.MGR_ID='''||p_mgrId||''')';
    end if;
    --当用户没有传产品ID
    if p_product_id is not null then 
      v_sql_count:=v_sql_count||'and t.PRODUCT_ID='''||p_product_id||'''';
      v_sql_count2:=v_sql_count2||'and t.PRODUCT_ID='''||p_product_id||'''';
    end if;
      v_sql_count2:=v_sql_count2||'group by t.credit_no,t.credit_type,t.product_id,to_char(t.APPLY_DATE,''yyyyMMdd''))';
    execute immediate v_sql_count into v_hasimportdata;
      
    --select count(*) into v_hasimportdata from  busi_sale_data t  where t.status = 0  and t.company_id = p_company_id and t.batch_number_id=p_batchid;
    if v_hasimportdata =0 then
        v_msg :='无导入数据，请先导入';
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg from dual;
        return;
    end if;

    /*select count(1) into v_count  from (select t.product_id from busi_sale_data t  where t.COMPANY_ID=p_company_id and to_char(t.APPLY_DATE,'yyyyMMdd') >= v_curdate_str and t.status='0' and t.batch_number_id=p_batchid 
           group by t.credit_no,t.credit_type,t.product_id,to_char(t.APPLY_DATE,'yyyyMMdd'));*/
    execute immediate v_sql_count2 into v_count;
    
    if v_hasimportdata !=v_count then
        v_msg :='数据(证件类型+证件号码）存在重复，请先确保数据不重复，再自动生成数据。';
        open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
        return;
    end if;
    
    --单产品跟多产品进行互斥的时候 是根据产品编号还有申请时间来互斥的
    begin
    v_sql_check:='select b.PRODUCT_ID, to_char(b.apply_date,''yyyy-MM-dd''),t.PRODUCT_NO from busi_sale_data b,busi_product t where t.id=b.PRODUCT_ID and b.BATCH_NUMBER_ID='''||p_batchId||'''';
    
    if p_product_id is not null then
      v_sql_check:=v_sql_check||' and b.PRODUCT_ID =''' ||p_product_id || '''';   
    end if;
      v_sql_check:=v_sql_check||' group by b.PRODUCT_ID,to_char(b.apply_date,''yyyy-MM-dd''),t.PRODUCT_NO';
    open pro_group_check for v_sql_check;
         loop
           fetch pro_group_check into v_product_id ,v_apply_date,v_product_no;
           exit when pro_group_check%notfound;
           
           select count(1) into v_buy_count from busi_sale_data s where s.status=1 and s.product_id=v_product_id and to_char(s.apply_date,'yyyy-MM-dd')=v_apply_date and s.BANK_ACCUNT_NO is not null;
            if v_buy_count> 0 then
                v_flag:=1;
               v_msg := v_msg||'已经在【'||v_apply_date||'】认购、申购过产品【'||v_product_no||'】,不需要重新录入;<br>';
            end if;
      end loop;
      close pro_group_check;
      end;
      
    
      
    v_sql_check:='select t.investor_name,t.credit_no,t.credit_type_code from busi_sale_data t where t.status = 0 and t.company_id ='''||p_company_id||'''
                 and t.batch_number_id='''||p_batchid||'''';
    
    v_sql_data:='select t.PRODUCT_ID, to_char(t.apply_date,''yyyy-MM-dd''), t.investor_name,t.credit_no,t.credit_type_code,t.legal_person,t.handel_person,t.bank_no,t.bank_name,t.open_bank_name,t.bank_accunt_no,t.amount,t.province_name,t.city_name,t.investor_type,t.bank_account_name,t.id from busi_sale_data t where t.status = 0 and t.company_id ='''||p_company_id||'''
                 and t.batch_number_id='''||p_batchid||'''';    
    if p_product_id is not null then
      --对单个产品进行确认
      v_sql_check:=v_sql_check|| ' and t.PRODUCT_ID =''' ||p_product_id || '''';
      v_sql_data:=v_sql_data|| ' and t.PRODUCT_ID =''' ||p_product_id || '''';
    end if;
    
   if p_isMgr=0 and p_mgrId is not null then
     v_sql_check:=v_sql_check||' and exists (select 1 from busi_product_authorization a where  a.PRODUCT_ID=t.PRODUCT_ID and a.MGR_ID='''||p_mgrId||''')';
     v_sql_data:=v_sql_data  ||' and exists (select 1 from busi_product_authorization a where  a.PRODUCT_ID=t.PRODUCT_ID and a.MGR_ID='''||p_mgrId||''')';
   end if;
   end;
   
 open data_cur_check for v_sql_check;
    loop
        fetch data_cur_check into v_investor_name ,v_credit_no,v_credit_type_code;
        exit when data_cur_check%notfound;
        
        begin
             select t.name into v_investor_name_ta  from busi_investor_credit t where  t.credit_type= v_credit_type_code and t.credit_no = v_credit_no and t.is_delete='0';
        exception
            when others then
            v_investor_name_ta :='';
        end;

        if v_investor_name_ta is not null and v_investor_name_ta <> v_investor_name then
             v_flag :=1;
             v_msg := v_msg||'证件号码('|| v_credit_no||')对应的投资人姓名('|| v_investor_name ||')与平台('||v_investor_name_ta||')不匹配,请确认客户姓名和证件号码;<br>';
        end if ;
    end loop;
    close data_cur_check;

    if v_flag = 1 then
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg  from dual;
        return ;
    end if ;
    
    --插入表操作start
    open data_cur for v_sql_data;
    loop
        fetch data_cur into v_product_id,v_apply_date,v_investor_name,v_credit_no,v_credit_type_code,v_legal_person,v_handel_person,v_bank_no,v_bank_name,v_open_bank_name,v_bank_accunt_no,v_rgje,v_province_name,v_city_name,v_investor_type,v_bank_account_name,v_tab_id;
        exit when data_cur%notfound;
    v_rg_je_ta:=null;
    v_sh_je_ta:=null;
    v_rsh_je_ta:=null;
    select count(1) into v_limit_count  from zsta.fundlimit@TA_dblink t, busi_product info where info.product_no=t.fundcode and info.id=v_product_id;
    if v_limit_count > 0 then
                  select minsubsamountbyindi, minbidsamountbyindi,minappbidsamountbyindi into v_rg_je_ta,v_sh_je_ta,v_rsh_je_ta from zsta.fundlimit@TA_dblink t, busi_product info where info.product_no=t.fundcode and info.id=v_product_id;
    end if;

    if trim(v_rg_je_ta) is null then
         v_rg_je_ta:='1000000';
    end if;
    if trim(v_sh_je_ta) is null then
         v_sh_je_ta:='1000000';
    end if;
        select to_date(v_apply_date||to_char(sysdate,'HH24:MI:SS'),'yyyy-MM-ddHH24:MI:SS')  into v_current_date from dual; 
        select decode(v_investor_type,'机构','2','个人','1') into v_user_type from dual;
        select count(*) into v_kh_count from busi_investor_credit t where t.credit_type = v_credit_type_code and t.credit_no = v_credit_no and t.is_delete='0';
        --如果是新开户，则作三张表插入操作
        if v_kh_count=0 then
              select sys_guid() into v_credit_id from dual;
              --客户表
              insert into busi_investor_credit (id,user_type,credit_type,credit_no, create_date,create_by,password,name )  --客户编号，触发器自动生成，不需要手工查询
                     values (v_credit_id,v_user_type,v_credit_type_code,v_credit_no,sysdate,p_create_by,md5(substr(v_credit_no,length(v_credit_no)-6+1,6)),v_investor_name);
              --开户申请表
              select sys_guid() into v_khsqid from dual;
              --生成申请单号
              select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
              insert into busi_investor_detail(id,investor_type,handle_person,legal_person,name,create_by,busi_type,company_id,apply_no,create_date,credit_type,credit_id,credit_no,manage_fee_mark,achieve_fee_mark,pt_id)
                 values(v_khsqid,v_user_type,v_handel_person,v_legal_person,v_investor_name,p_create_by,'001',p_company_id,v_apply_no,v_current_date,v_credit_type_code,v_credit_id,v_credit_no,'是','是',v_product_id);
                 --关联基金公司
              insert into BUSI_CREDIT_COMPANY (credit_id,company_id,Sqrq,ismustsetpass,is_active) values(v_credit_id,p_company_id,v_current_date,1,0);
        end if;

        --存在客户
        if v_kh_count >0 then
            select t.id,t.custom_no into v_credit_id,v_custom_no from busi_investor_credit t where  t.credit_type = v_credit_type_code and t.credit_no = v_credit_no;
            select count(*) into v_khsq_count from busi_investor_detail t where t.credit_id=v_credit_id and t.company_id=p_company_id and t.is_delete='0';
            --未开户
            if v_khsq_count =0 then
                -- 查一次是否有其他公司开户。之前是如果有其它公司开户，业务类型为增开账户。现在改为只要没有登记账户，业务类型就为开户。modify by xiaxn。
                select count(*) into v_khsq_count from busi_investor_credit c where c.id=v_credit_id and c.is_delete ='0' and c.regist_account is not null;
                select sys_guid() into v_khsqid from dual;
                select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                -- 插入开户记录，其中 业务类型  001  开户  008 增加交易账户
                insert into busi_investor_detail(id,investor_type,handle_person,legal_person,name,create_by,busi_type,company_id,apply_no,create_date,credit_type,credit_id,credit_no,manage_fee_mark,achieve_fee_mark,pt_id)
                   values(v_khsqid,v_user_type,v_handel_person,v_legal_person,v_investor_name,p_create_by,(case when v_khsq_count>0 then '008' else '001' end),p_company_id,v_apply_no,v_current_date,v_credit_type_code,v_credit_id,v_credit_no,'是','是',v_product_id);
            
                select count(*) into v_fundcomp_count from  busi_credit_company t where t.credit_id=v_credit_id  and t.company_id=p_company_id;
                --关联基金公司
                if v_fundcomp_count = 0 then
                       insert into busi_credit_company (credit_id,company_id,sqrq,ismustsetpass,is_active) values(v_credit_id,p_company_id,v_current_date,1,0);
                else
                  UPDATE busi_investor_credit t SET t.SOURCETYPE='0',t.is_delete='0'  WHERE  id=v_credit_id;
                  UPDATE BUSI_CREDIT_COMPANY c SET c.SOURCETYPE='0',c.insti_name=(case when c.insti_name is null then '直销' else c.insti_name end),c.sqrq=v_current_date WHERE c.credit_id=v_credit_id AND c.company_id=p_company_id;
                end if;
            end if;
           end if;
        select child_buy_or_sale_prarent(v_credit_id,v_product_id,'01',null) into v_son_buy_monther from dual;

       if v_son_buy_monther='true' then
             v_flag := '1';
             v_msg := v_msg||'投资人(''' ||v_credit_no ||''')申购子基金，会自动出发子基金申购母基金，请勿重复录单<br>';
       elsif v_son_buy_monther <> 'true' and  v_son_buy_monther <> 'false' then
          insert into t_fund_job_running_log (JOB_NAME,job_running_log) values ('子买母问题',v_son_buy_monther || '    '||v_credit_id || '    '|| v_product_id || v_current_date );
       end  if;

 
        --查询基金状态
        select t.publish_status,t.is_limit_buy,start_price,t.product_no,name into  v_publish_status,v_is_limit_buy,v_start_price,v_product_no,v_product_name from busi_product t  where t.id=v_product_id;
        
        select count(1) into v_buy_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=v_product_id and t.business_type in('020','022')  and to_char(t.sheet_create_time,'yyyy-MM-dd')  = v_apply_date  and t.is_delete='0' ;
            if v_buy_count> 0 then
               v_flag:=1;
               v_msg := v_msg||'证件号码：'||v_credit_no||',姓名：'||v_investor_name||',已经在【'||v_apply_date|| '】认购、申购过产品【'||v_product_no||'】,不需要重新录入;<br>';
            end if;
            
       
       
        
            
        --本地是发行状态，则类型为认购，本地不是发行状态则根据产品代码与日期去TA查询基金状态，非发行则全为申购
        if (v_publish_status='1' or v_publish_status='2')       then
              v_busi_type :='认购';
              v_busi_type_code :='020';
        elsif ( v_publish_status='0'  or v_publish_status='6')   then  -- 0 正常交易，6 （停止赎回）可申购
            v_busi_type :='申购';
            v_busi_type_code :='022';
        else
           -- select t.jjzt into v_publish_status from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm =v_product_no and t.rq=to_date(p_applay_date,'yyyy-MM-dd');
            begin
                select t.jjzt,1 into v_publish_status,v_pt_status_count from t_rlb_jjzt t where t.jjdm =v_product_no and t.rq = to_char(to_date(v_applay_date,'yyyy-MM-dd'),'yyyyMMdd');
            exception   when no_data_found then
                v_pt_status_count:=0;
            end;

            if v_pt_status_count > 0 then
                if v_publish_status='1' or v_publish_status='2' then -- 1(发行) 2（发行成功）
                     v_busi_type :='认购';
                     v_busi_type_code :='020';
                else
                     v_busi_type :='申购';
                     v_busi_type_code :='022';
                end if;
            else
                v_flag := '1';
                v_msg := '产品:' || v_product_name || ' 在日期' || v_applay_date || '不是临时开放日，不能导入订单';
            end if;

        end if;

         --认申购额度做限制的时候
        if v_is_limit_buy=1 then
             --认购最低金额
            if v_busi_type_code='020' then       -- 认购
                  select count(1) into  v_trade_count  from busi_sheet  t where  t.credit_id=v_credit_id and t.pt_id = p_product_id and  t.business_type = v_busi_type_code  and t.is_delete='0';
                  if v_trade_count  <1  then
                      select to_number(replace(v_rg_je_ta,',',''),'9999999999999999.999999') into v_rgje_ta from dual;
                      select to_number(replace(v_rgje,',',''),'9999999999999999.999999')  into v_rgje_number from dual; -- 认购金额
                      if(v_rgje_ta>(v_rgje_number)) then
                           v_flag := '1';
                           v_msg := v_msg||'证件号码：'||v_credit_no||'姓名：'||v_investor_name||'认购金额小于最低认购金额;<br>';
                      end if;
                  else
                      v_flag := '1';
                      v_msg := v_msg||'证件号码：'||v_credit_no||'姓名：'||v_investor_name||'已经认购过此产品;<br>';
                  end if;
            end if;

            --申购最低金额
            if v_busi_type_code ='022' and v_limit_count >0 then

                select to_number(replace(v_sh_je_ta,',',''),'9999999999999999.999999') into v_rgje_ta from dual;
                select to_number(replace(v_rsh_je_ta,',',''),'9999999999999999.999999') into v_sg_rgje_ta from dual;
                select to_number(replace(v_rgje,',',''),'9999999999999999.999999') into v_rgje_number from dual;

                    select count(1) into  v_trade_count  from busi_sheet  t where  t.credit_id=v_credit_id and t.pt_id = p_product_id and  t.business_type in('020','022')  and t.is_delete='0';
                    -------------------申购和追加申购判断
                    if v_trade_count >0 then
                        if(v_sg_rgje_ta>(v_rgje_number)) then
                            v_flag := '1';
                            v_msg := v_msg||'证件号码：'||v_credit_no||'姓名：'||v_investor_name||'追加申购金额小于最低追加申购金额;<br>';
                        end if;
                    else
                        if(v_rgje_ta>(v_rgje_number)) then
                            v_flag := '1';
                            v_msg := v_msg||'证件号码：'||v_credit_no||'姓名：'||v_investor_name||'申购金额小于最低申购金额;<br>';
                        end if;
                    end if;

            end if;

        end if;

        if v_flag <> 1 then
            --开过这个账号，不需要再次开户
            begin
                 select  id,is_back_account,1 into v_bank_card_id,v_is_back_account,v_bank_accunt_no_count from busi_bind_bank_card bc
                 where  bc.credit_id = v_credit_id and bc.product_id = v_product_id and bc.account_no = v_bank_accunt_no and bc.bank_no = v_bank_no and is_delete='0' and rownum=1;
            exception  when no_data_found then
                 v_bank_accunt_no_count:=0;
                 if  (v_bank_accunt_no is not null) and (v_bank_account_name is not null) and (v_bank_no is not null)  then
                 v_bank_card_id:=sys_guid();
                 else
                   v_bank_card_id:=null;
                 end if;

            end;

            select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;--生成申请单号
            select sys_guid() into v_table_id from dual;
            --插入交易申请表busi_sheet.导入时做了转换，这里不需要在转换
            -- select round(v_rgje*10000,6) into v_ex_rgje from dual;--认购金额扩大10000倍，保留6位小数

            --获取投资人详情id
            if(v_khsqid is null) then
                select d.id into v_khsqid from busi_investor_detail d where d.credit_id=v_credit_id and  company_id = p_company_id and  is_delete='0' and rownum=1;
            end if;

            insert into busi_sheet(id,sheet_no,sheet_create_time,business_type,pt_id,pt_no,apply_amount,credit_id,create_by,company_id,
               manager_contract_status,investor_contract_status,trustee_contract_status,fund_is_receive,status,manager_fund_confirm,create_date,bank_card_id,dt_id
            ) values (v_table_id,v_apply_no,v_current_date,v_busi_type_code,v_product_id,v_product_no,v_rgje,v_credit_id,p_create_by,
               p_company_id, '1','1', '1',  '1', '1', '1',sysdate,v_bank_card_id,v_khsqid);

             --插入银行账户登记
            --对银行账户登记可放开，当五项（银行账号、银行户名、开户行名称、省份、城市）全填写时，才让其它登记银行信息
             if  ( v_bank_accunt_no_count <1 ) then  -- 不存在产品对应的银行卡
                 if  (v_bank_accunt_no is not null) and (v_bank_account_name is not null) and (v_bank_no is not null)  then
                      --第一次录入的默认赎回分红账户，之后的默认非赎回分红账户
                      select count(1) into v_bank_accunt_no_count from busi_bind_bank_card  t where  t.credit_id=v_credit_id and t.product_id=v_product_id  and is_delete='0' and t.is_back_account='1';
                      if  (v_province_name is not null)  then
                           select id,name into v_province_code,v_province_name_db from busi_region where name like v_province_name || '%' and parent_id is null; --获取省份ID
                      end if;

                      if  (v_city_name is not null)  then
                          select id,name into v_city_code,v_city_name_db from busi_region where name like v_city_name || '%' and parent_id is not null;     --获取城市id
                      end if;

                      select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;--生成申请单号

                      if v_bank_accunt_no_count> 0 then
                           v_is_back_account := '0';
                      else
                           v_is_back_account := '1';
                      end if;

                      insert into busi_bind_bank_card(id,credit_id,user_name,bank_no,bank_name,open_bank_name,province_id,province_name,city_id,city_name,
                                 account_no,product_id,company_id,apply_no,bind_date,create_date, create_by,is_back_account
                          ) values ( v_bank_card_id,v_credit_id,v_investor_name,v_bank_no,v_bank_name,v_open_bank_name,v_province_code,v_province_name_db,
                                 v_city_code, v_city_name_db,v_bank_accunt_no,v_product_id,p_company_id,v_apply_no,v_current_date,sysdate,
                                 p_create_by,v_is_back_account );
                --else
                    --  v_flag := '1';
                    --  v_msg := v_msg||'证件号码：'||v_credit_no||'姓名：'||v_investor_name||'银行卡信息不存在;<br>';
                    --   exit;
                end if;
            else
                  select count(1) into v_bank_accunt_no_count from busi_bind_bank_card where  credit_id=v_credit_id and product_id=p_product_id  and is_delete='0';
                  if (v_bank_accunt_no_count=1) then -- 唯一的账号就设置成分红账号
                        update busi_bind_bank_card set is_back_account= '1',update_by =p_create_by,update_date=sysdate  where id = v_bank_card_id;
                  end if;
            end if;
            --把产品成立表的数据根据ID改变状态
            update busi_sale_data set status=1 where id = v_tab_id;
        end if;
    end loop;
    close data_cur;

    if v_flag = 1 then
        rollback;
         v_msg:= substr(v_msg,0,999); 
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg  from dual; 
    else
      --插入成功信息
        v_msg :='生成数据成功';
        open c_result for select v_job_name as flag,'success' as res, v_msg as msg from dual;     
    end if ;  
    
    insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
    commit;
    return ;

    exception
        when others then
        begin
            rollback;
            DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
            DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
            v_msg:=v_credit_no||':'||sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();
            v_msg:= substr(v_msg,0,999);
            insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
            open c_result for select v_job_name as flag,'faile', v_msg as msg from dual;
            commit;
            return;
        end ;
 end tgyw_rsg_sheet_multi;
/

