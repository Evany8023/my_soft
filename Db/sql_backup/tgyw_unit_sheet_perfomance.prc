create or replace procedure smzj.tgyw_unit_sheet_perfomance(p_apply_date in varchar2, --申请日期
                                            p_cp_id  in varchar2, -- 公司ID
                                            p_pt_id in varchar2, --产品ID
                                            p_credit_id in varchar2,--证件id
                                            p_credit_type in varchar2, -- 证件类型
                                            p_credit_no in varchar2,  --证件号码
                                            p_name in varchar2, --客户姓名
                                            p_user_type in varchar2, --投资人用户类型
                                            p_zip_code in varchar2, --邮政编码
                                            p_address in varchar2, --通讯地址
                                            p_telephone in varchar2, --联系电话
                                            p_phone in varchar2, --手机号码
                                            p_email in varchar2, --邮箱
                                            p_link_man in varchar2, --联系人姓名
                                            p_handel_person in varchar2, --经办人
                                            p_legal_person in varchar2, --法人代表
                                            p_dt_remark in varchar2, --开户备注

                                            p_is_new_credit in varchar2, --是否新证件（1：是，0：否）


                                            p_is_new_bank_card in varchar2, --是否新银行账户（1：是，0：否）
                                            p_bank_card_id in varchar2, -- 银行卡ID
                                            p_bank_no in out varchar2, --银行编号
                                            p_bank_name in varchar2, --银行名称
                                            p_link_bank_no in varchar2, --联行号
                                            p_account_no in out varchar2, --银行账号
                                            p_account_name in varchar2, --银行户名
                                            p_open_bank_name in varchar2, --开户行名称
                                            p_province_id in varchar2, --省份ID
                                            p_province_name in varchar2, -- 省份名称
                                            p_city_id in varchar2, --城市ID
                                            p_city_name in varchar2, --城市名称
                                            p_is_back_account in  varchar2, --是否赎回分红账号
                                            p_bank_card_remark in varchar2, --银行卡备注

                                            p_sheet_busi_type in varchar2, -- 订单业务类型
                                            p_amount in varchar2, --订单金额
                                            p_sheet_remark in varchar2, -- 订单备注

                                            p_create_by in varchar2, --创建人
                                            c_result out sys_refcursor) is
---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_unit_sheet
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:
--                 管理人单笔录入认/申购订单
-- CREATE DATE:  2015-10-30
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
 v_job_name varchar2(100) :='tgyw_unit_sheet';
 v_msg varchar2(1000); --错误信息
 v_is_sheet char(1); --公司是否停止录单
 v_credit_id varchar2(32); --证件ID
 v_detail_id varchar2(32); --详情ID
 v_bank_card_id varchar(32); --银行卡ID
 v_credit_no  varchar(32); -- 个人证件号码
 v_fundcomp_count number;


 v_name busi_investor_credit.name%type; --投资人姓名
 v_credit_count number; --判断证件是否存在
 v_detail_count number; --判断是否开户
 v_apply_no busi_investor_detail.apply_no%type; --开户申请单号

 v_bank_card_count number; --客户银行卡数量，判断是否添加过银行卡
 v_is_back_account number; --判断是否赎回分红账户
 v_same_bank_count number; --判断银行卡是否重复

 v_start_price busi_product.start_price%type; --认申购起点
 v_plus_start_price busi_product.plus_start_price%type;  --追加申购起点
 v_is_limit_buy busi_product.is_limit_buy%type; --认申购是否做限制
 v_buy_count number; --购买次数
 v_trade_count number; --购买次数
  v_investor_name_ta varchar2(50 char);--ta投资者姓名
 v_buy_amount number; --订单购买金额
 v_limit_amount number; --限制金额
 v_pt_no  varchar2(16); -- 产品编号
 v_flag integer :=0;--业务处理结果，如果为1，回滚事物
 v_current_date date; --当前时间
 v_double_count integer;
 v_double_ynzh_count integer;
 v_is_back_account_value varchar2(1);
 v_son_buy_monther varchar2(200 char); --子买母返回值
 v_sheet_id varchar2(50);             --订单表的id
begin
     v_flag:=0;
    v_bank_card_count := 0;
    select cp.is_sheet into v_is_sheet from busi_company cp where cp.id = p_cp_id;
    if v_is_sheet = '1' then
      v_msg := '现在已停止录单，请稍后提交订单';
      open c_result for select 'faile' as res, v_msg as msg from dual;
      return;
    end if;

     if trim(p_credit_no) is not null  then
      v_credit_no:=UPPER(p_credit_no);
    end if;

       begin
             select t.name into v_investor_name_ta  from busi_investor_credit t where  t.credit_type= p_credit_type and t.credit_no = p_credit_no and t.is_delete='0';
        exception
            when others then
            v_investor_name_ta :='';
        end;

        if v_investor_name_ta is not null and v_investor_name_ta <> p_name then
             v_flag :=1;
             v_msg := v_msg||'证件号码('|| p_credit_no||')对应的投资人姓名('|| p_name ||')与平台('||v_investor_name_ta||')不匹配,请确认客户姓名和证件号码;<br>';
             open c_result for select 'faile' as res, v_msg as msg from dual;
              return;
        end if ;


   select to_date(p_apply_date||to_char(sysdate,'HH24:MI:SS'),'yyyy-mm-ddHH24:MI:SS') into v_current_date from dual;
 --新增客户
    if p_is_new_credit = '1' then
                  select count(1) into v_credit_count from busi_investor_credit cr where cr.credit_type = p_credit_type and cr.credit_no = p_credit_no;
                   --如果是新证件插入三张表
                  if v_credit_count = 0 then
                        select sys_guid() into v_credit_id from dual;
                        select sys_guid() into v_detail_id from dual;
                        v_name:=p_name;
                        insert into busi_investor_credit(id,credit_type,credit_no,name,user_type,password, create_by,create_date,is_examine,is_active,is_delete)
                        values
                       (v_credit_id,p_credit_type,p_credit_no,p_name,p_user_type,md5(substr(p_credit_no,length(p_credit_no)-6+1,6)),p_create_by,sysdate,'1','0','0');

                       --生成申请单号
                       select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                       insert into busi_investor_detail(id,investor_type,HANDLE_PERSON,legal_person,link_man,name,create_by,busi_type,company_id,apply_no,create_date,credit_id,credit_type,credit_no,MANAGE_FEE_MARK,ACHIEVE_FEE_MARK,ZIP_CODE,ADDRESS,TELEPHONE,PHONE,EMAIL,REMARK,is_delete,pt_id)
                             values(v_detail_id,p_user_type,p_handel_person,p_legal_person,p_link_man, p_name,p_create_by,'001',p_cp_id,v_apply_no,v_current_date,v_credit_id,p_credit_type,p_credit_no,'是','是',p_zip_code,p_address,p_telephone,p_phone,p_email,p_dt_remark,'0',p_pt_id);
                         --关联基金公司
                       insert into BUSI_CREDIT_COMPANY (credit_id,company_id,Sqrq,Ismustsetpass,Is_Active) values(v_credit_id,p_cp_id,v_current_date,1,0);
                  else
                      --如果证件已经存在，查出证件ID和名字
                      select cr.id,cr.name,cr.credit_no into v_credit_id, v_name,v_credit_no from busi_investor_credit cr where cr.credit_type = p_credit_type and cr.credit_no = p_credit_no and rownum=1;
                          --证件存在时判断名称是否相同

                     select count(1) into v_detail_count from busi_investor_detail dt where dt.credit_id = v_credit_id and dt.company_id = p_cp_id  and dt.is_delete='0';
                          --客户名称对得上时。判断是否已经开过户
                     if v_detail_count < 1 then
                          --select count(1) into v_detail_count from busi_investor_detail dt where dt.credit_id = v_credit_id  and dt.is_delete='0';
                          select count(*) into v_detail_count from busi_investor_credit cr where cr.id = v_credit_id  and cr.is_delete='0' and cr.regist_account is not null;
                          select sys_guid() into v_detail_id from dual;
                              --判断客户是否已经在其他公司开过户，开过户的业务类型为：增开客户（008），没开过为：新增客户（001）
                          select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                          insert into busi_investor_detail(id,investor_type,HANDLE_PERSON,legal_person,link_man,name,create_by,busi_type,company_id,apply_no,create_date,credit_id,credit_type,credit_no,MANAGE_FEE_MARK,ACHIEVE_FEE_MARK,ZIP_CODE,ADDRESS,TELEPHONE,PHONE,EMAIL,REMARK,is_delete,pt_id)
                                   values(v_detail_id,p_user_type,p_handel_person,p_legal_person,p_link_man,p_name,p_create_by,(case when v_detail_count=0 then '001' else '008' end),p_cp_id,v_apply_no,v_current_date,v_credit_id,p_credit_type,p_credit_no,'是','是',p_zip_code,p_address,p_telephone,p_phone,p_email,p_dt_remark,'0',p_pt_id);
                     else
                          v_msg := '你添加的客户已经存在，请不要重复添加';
                          open c_result for select 'faile' as res, v_msg as msg from dual;
                          return;
                     end if;

                     select count(*) into v_fundcomp_count from  busi_credit_company t where t.credit_id=v_credit_id  and t.company_id=p_cp_id;
                          --关联基金公司
                     if v_fundcomp_count = 0 then
                             insert into busi_credit_company (credit_id,company_id,sqrq) values(v_credit_id,p_cp_id,v_current_date);
                      end if;

                       UPDATE busi_investor_credit t SET t.SOURCETYPE='0',t.is_delete='0' WHERE  id=v_credit_id;
                       UPDATE BUSI_CREDIT_COMPANY c SET c.SOURCETYPE='0',c.insti_name='直销,'||c.insti_name,c.sqrq=v_current_date WHERE c.credit_id=v_credit_id AND c.company_id=p_cp_id;

                  end if;

    else --老账户
        v_credit_id := p_credit_id;
        begin
            select dt.id into v_detail_id from busi_investor_detail dt where dt.credit_id = v_credit_id and dt.company_id = p_cp_id and is_delete='0'and rownum=1;
            select cr.credit_no,cr.name into v_credit_no,v_name from  busi_investor_credit cr where cr.id=v_credit_id;
            UPDATE busi_investor_credit t SET t.SOURCETYPE='0',t.is_delete='0' WHERE  id=v_credit_id;
        exception   when no_data_found then
            v_msg := '客户已销户';
            open c_result for select 'faile' as res, v_msg as msg from dual;
            return;
        end;
    end if;


     select child_buy_or_sale_prarent(v_credit_id,p_pt_id,'01',null) into v_son_buy_monther from dual;
       if v_son_buy_monther='true' then
             v_flag := '1';
            v_msg := v_msg||'投资人(''' ||v_credit_no ||''')申购子基金，会自动出发子基金申购母基金，请勿重复录单<br>';
       elsif v_son_buy_monther <> 'true' and  v_son_buy_monther <> 'false' then
          insert into t_fund_job_running_log (JOB_NAME,job_running_log) values ('子买母问题',v_son_buy_monther || '    '||v_credit_id || '    '|| p_pt_id || v_current_date );
       end  if;

    select count(1) into v_is_back_account from busi_bind_bank_card bc where bc.credit_id = v_credit_id and bc.product_id = p_pt_id and bc.is_back_account = '1'  and is_delete='0';
   if v_is_back_account > 0 then
         v_is_back_account_value:='0';
      else
         v_is_back_account_value:='1';
   end if;
    --新增银行账户
    if p_is_new_bank_card = '1' then
        select count(1) into v_bank_card_count from busi_bind_bank_card bc where bc.credit_id = v_credit_id and bc.product_id = p_pt_id and is_delete='0';
        select count(1) into v_same_bank_count from busi_bind_bank_card bc where bc.credit_id = v_credit_id and bc.product_id = p_pt_id and bc.account_no = p_account_no and bc.bank_no = p_bank_no and is_delete='0';
        if v_is_back_account > 0 and p_is_back_account = '1' then
            v_flag := 1;
            v_msg := '该客户已设置有分红赎回账户（同一客户、同一产品只能设置一个分红账户）';
        elsif v_same_bank_count > 0 then
            v_flag := 1;
            v_msg := '银行卡已经存在，请不要重复添加';
        else
            select sys_guid() into v_bank_card_id from dual;
            select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
            insert into busi_bind_bank_card(id,credit_id,user_name, bank_no, bank_name,open_bank_name, province_id,province_name, city_id, city_name, account_no,product_id, company_id, apply_no, bind_date, create_date,create_by, is_back_account,link_bank_no,remark)
                         values (v_bank_card_id,v_credit_id, p_account_name,p_bank_no, p_bank_name,p_open_bank_name, p_province_id,p_province_name, p_city_id, p_city_name,p_account_no, p_pt_id, p_cp_id, v_apply_no, v_current_date, sysdate, p_create_by, p_is_back_account,p_link_bank_no,p_bank_card_remark);
        end if;
    else

       select count(1) into v_double_count from busi_bind_bank_card  where id = p_bank_card_id;
       if v_double_count > 0 then
          select account_no,bank_no,1 into p_account_no, p_bank_no,v_bank_card_count from busi_bind_bank_card  where id = p_bank_card_id;
       end if;

       --验证银行卡是否存在
        if v_bank_card_count = 0 then
            v_flag := 1;
            v_msg := '不能获取银行账号信息，请选择其他银行卡下单';
        else
            v_bank_card_count := 0;
            select count(1) into v_double_ynzh_count   from busi_bind_bank_card bc  where bc.credit_id = p_credit_id and bc.product_id = p_pt_id
            and bc.account_no = p_account_no and bc.bank_no = p_bank_no  and is_delete='0' ;
            if v_double_ynzh_count> 0 then
                 select ID,1 into v_bank_card_id,v_bank_card_count from busi_bind_bank_card bc  where bc.credit_id = p_credit_id and bc.product_id = p_pt_id
                 and bc.account_no = p_account_no and bc.bank_no = p_bank_no  and is_delete='0' and rownum=1;
            end if;

            --判断银行卡是否和当前的产品关联，如果有就跳过，没有就再生成一条

            if v_bank_card_count = 0 then
                  select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                  select sys_guid() into v_bank_card_id from dual;
                  insert into busi_bind_bank_card(id,product_id,apply_no, bind_date, create_date,create_by, credit_id,user_name, bank_no, bank_name,open_bank_name,
                     province_id,province_name, city_id, city_name, account_no,company_id, is_back_account,link_bank_no,remark,is_delete)
                  select v_bank_card_id,p_pt_id, v_apply_no, v_current_date, sysdate,p_create_by,v_credit_id,user_name,bank_no,bank_name,open_bank_name,
                     province_id,province_name, city_id, city_name, account_no, company_id, v_is_back_account_value,link_bank_no,remark,'0'  from  busi_bind_bank_card where id = p_bank_card_id;

            else

               if (p_is_back_account = '1') and v_is_back_account< 1 then
                    update busi_bind_bank_card set is_back_account='1',  update_by =p_create_by,update_date=sysdate  where id = v_bank_card_id;
               end if;
            end if;
         end if;
    end if;

    select count(1) into v_trade_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=p_pt_id and t.business_type in('022','020')  and to_char(t.sheet_create_time,'yyyy-MM-dd') = p_apply_date  and t.is_delete='0';
      if v_trade_count>0 then
          v_flag := '1';
          v_msg := '证件号码：'||v_credit_no||',姓名：'||v_name||',在'||p_apply_date||'已经认购、申购过此产品,不能再次申请;';
      end if;


    select pt.start_price,pt.plus_start_price, pt.is_limit_buy,product_no into v_start_price, v_plus_start_price, v_is_limit_buy,v_pt_no from busi_product pt where pt.id = p_pt_id;
     --认申购额度做限制的时候
         if v_is_limit_buy=1 then

             --认购最低金额
             if p_sheet_busi_type='020' then       -- 认购
                  select count(1) into v_buy_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=p_pt_id and t.business_type = p_sheet_busi_type and t.is_delete='0';

                  if v_start_price is null  then
                     v_start_price:='1000000';
                  end if;
                  if v_buy_count<1  then

                       select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
                       select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
                       if v_buy_amount < v_limit_amount then
                           v_flag := 1;
                           v_msg := '认购金额不能小于：'|| v_start_price ||'元';
                       end if;
                  else
                      v_flag := '1';
                      v_msg := '证件号码：'||v_credit_no||',姓名：'||v_name||',已经认购过此产品,不能再认购;';
                  end if;
             end if;

            --申购最低金额
            if p_sheet_busi_type ='022' then

               if v_start_price is null  then
                     v_start_price:='1000000';
               end if;

                       select count(1) into v_buy_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=p_pt_id  and  t.business_type in('020','022') and  t.is_delete='0';
                       --申购分申购和追加申购的判断
                       if v_buy_count < 1 then
                          select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
                          select to_number(v_start_price,'9999999999999999.9999') into v_limit_amount from dual;
                          if v_buy_amount < v_limit_amount then
                            v_flag := 1;
                            v_msg := '申购金额不能小于：'|| v_start_price ||'元';
                          end if;
                       else
                           if v_plus_start_price is not null then
                                           select to_number(p_amount,'9999999999999999.9999') into v_buy_amount from dual;
                                           select to_number(v_plus_start_price,'9999999999999999.9999') into v_limit_amount from dual;
                                           if v_buy_amount < v_limit_amount then
                                            v_flag := 1;
                                            v_msg := '证件号码：'||v_credit_no||'姓名：'||v_name||'追加申购金额不能低于'||v_limit_amount||'元';
                                          end if;

                           end if;

                       end if;


            end if;
        end if;


    if v_flag <> 1 then
        select sys_guid()  into  v_sheet_id from dual;
        select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
        insert into busi_sheet(id,sheet_no, sheet_create_time,business_type, pt_id,pt_no, apply_amount,credit_id, BANK_CARD_ID,DT_ID,create_by,company_id,manager_contract_status,investor_contract_status,trustee_contract_status,fund_is_receive,status, manager_fund_confirm,create_date,INVESTOR_MESSAGE,is_delete)
              values (v_sheet_id,v_apply_no,v_current_date,p_sheet_busi_type,p_pt_id,v_pt_no,p_amount,v_credit_id,v_bank_card_id, v_detail_id, p_create_by,p_cp_id, '1','1', '1','1','1','1', sysdate,p_sheet_remark,'0');
    end if;

     if v_flag = 1 then
        rollback;
        open c_result for select 'faile' as res, v_msg as msg  from dual;
    else
        v_msg := '添加订单成功';
        open c_result for select 'success' as res, v_msg as msg,v_sheet_id as sheetid  from dual;
        commit;
    end if;
    return;

    exception
        when others then
        begin
            rollback;
            DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
            DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
            v_msg:= sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace() || v_start_price || p_pt_id;
            insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
            open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
            commit;
            return;
        end ;
end tgyw_unit_sheet_perfomance;
/

