create or replace procedure smzj.sale_data_order(p_companyid in varchar2,
                                            p_productid in varchar2,
                                          --  p_businesstype   in varchar2,
                                            p_flag   in varchar2,
                                            p_create_user in varchar2
                                            --r_flag out varchar2,
                                            --,r_msg out varchar2
                                            ,c_result out sys_refcursor) is

 v_count integer;--记录已经生成数据条数
 v_msg varchar2(4000);--返回信息
 v_hasimportdata integer :=1;--判断是否有导入数据
 v_sale_data_id busi_sale_data.id%type;--销售数据临时表ID
 v_investor_name busi_sale_data.investor_name%type;--投资者姓名
 v_amount busi_sale_data.amount%type;--认购金额
 v_investor_type busi_sale_data.investor_type%type;--投资者类型
 v_credit_type busi_sale_data.credit_type%type;--证件类型
 v_credit_no busi_sale_data.credit_no%type;--证件号码
 v_handel_person busi_sale_data.handel_person%type;--经办人姓名
 v_legal_person busi_sale_data.legal_person%type;--法人姓名
 v_bank_accunt_no busi_sale_data.bank_accunt_no%type;--银行账号
 v_bank_account_name busi_sale_data.bank_account_name%type;--银行户名
 v_open_bank_name busi_sale_data.open_bank_name%type;--开户行名称
 v_province_name busi_sale_data.province_name%type;--省份
 v_city_name busi_sale_data.city_name%type;--城市
 v_product_id busi_sale_data.product_id%type;--产品ID
 v_company_id busi_sale_data.company_id%type;--私募公司ID
 v_business_type_name busi_sale_data.business_type%type;--业务类型
 v_apply_date busi_sale_data.apply_date%type;--业务类型

 v_investor_type_code  varchar2(50);--投资者类型编码
 v_credit_type_code  varchar2(50);--证件类型编码
 v_kh_count integer;--判断客户表是否存在此客户
 v_investor_detail_count integer;--判断是否有客户详情记录
 v_mgr_customer_count integer;--判断是否存在客户与公司关联记录
 v_investor_credit_id varchar2(32);--客户开户ID
 v_investor_detail_id varchar2(32);--客户开户详情信息ID
 v_mgr_customer_id varchar2(32);--客户与私募公司关联表ID
 v_bank_card_id varchar2(32);--银行账户ID
 v_province_id varchar2(32);--省份id
 v_city_id varchar2(32);--城市id
 v_order_no varchar2(32);--订单编号
 v_business_type varchar2(32);--业务类型
 v_apply_no varchar(64);

 --查询当天导入销售数据临时表未处理数据
 cursor data_cur  is select d.id,d.investor_name,d.amount,d.investor_type,d.credit_type,d.credit_no,d.handel_person,d.legal_person,
                            d.bank_accunt_no,d.bank_account_name,d.open_bank_name,d.province_name,d.city_name,d.product_id,d.company_id,
                            d.business_type,d.apply_date
    from busi_sale_data d
   where d.status = '0'
     and d.product_id = p_productid
     and d.company_id = p_companyid
     --and d.business_type = p_businesstype
     and to_date(to_char(d.create_date,'yyyy/MM/dd'),'yyyy/MM/dd') = to_date(to_char(sysdate,'yyyy/MM/dd'),'yyyy/MM/dd')
     and d.create_date = (select max(create_date) create_date from busi_sale_data );

 --处理开始
 begin
     --查询销售数据临时表当天是否已处理导入数据
     select count(*) into v_count
      from busi_sale_data d
     where d.status = '1'
       and d.product_id = p_productid
       and d.company_id = p_companyid
       --and d.business_type = p_businesstype
       and to_date(to_char(d.create_date,'yyyy/MM/dd'),'yyyy/MM/dd') = to_date(to_char(sysdate,'yyyy/MM/dd'),'yyyy/MM/dd');

     --查询业务类型名称
     --select d.label into v_business_type_name from sys_dict d where d.type = 'sheet_business_type' and d.value = p_businesstype;
     if v_count > 0 then
        v_msg := '指定产品申/认购已自动生成过数据，不能再次生成。';
        --open c_result for select p_flag as flag,'faile' as res, v_msg as msg  from dual;
        --插入错误信息
        open c_result for select p_flag as flag,'fail' as res, v_msg as msg from dual;
        --r_flag := 'faile';
        --r_msg := v_msg;
        return;
      end if;

      --查询销售数据临时表当天是否已导入数据
      select count(*) into v_hasimportdata from  busi_sale_data d
       where d.status = '0'
         and d.product_id = p_productid
         and d.company_id = p_companyid
         --and d.business_type = p_businesstype
         and to_date(to_char(d.create_date,'yyyy/MM/dd'),'yyyy/MM/dd') = to_date(to_char(sysdate,'yyyy/MM/dd'),'yyyy/MM/dd')
         and d.create_date = (select max(create_date) create_date from busi_sale_data );
       if v_hasimportdata =0 then
       v_msg :='无导入数据，请先导入';
       open c_result for select p_flag as flag,'fail' as res, v_msg as msg from dual;
        --r_flag := 'faile';
        --r_msg := v_msg;
       return;
       end if;

       --循环销售临时表数据
       open data_cur ;
       loop
           fetch data_cur into v_sale_data_id,v_investor_name,v_amount,v_investor_type,v_credit_type,v_credit_no,v_handel_person,v_legal_person,v_bank_accunt_no,v_bank_account_name,
                               v_open_bank_name,v_province_name,v_city_name,v_product_id,v_company_id,v_business_type_name,v_apply_date;
           --无数据就退出本次循环
           if data_cur%notfound then
              v_msg :='没有导入数据';
              open c_result for select p_flag as flag,'fail' as res, v_msg as msg from dual;
              exit;
           end if;

           --查询此客户是否开户，根据证件类型和证件号码查询
           select d.value into v_investor_type_code from sys_dict d where d.type = 'investor_user_type' and trim(d.label) = trim(v_investor_type);
           select d.value into v_credit_type_code from sys_dict d where d.type = 'credit_type' and trim(d.label) = trim(v_credit_type);
           select count(*) into v_kh_count  from busi_investor_credit c where c.credit_type = v_credit_type_code and c.credit_no = v_credit_no and c.is_delete = 0;

           --1.如果是新客户,新账号
           if v_kh_count=0 then
            select sys_guid() into v_investor_credit_id from dual;

            --插入客户证件表
            insert into busi_investor_credit
              (ID,
               CREDIT_TYPE,
               CREDIT_NO,
               USER_TYPE,
               NAME,
               CREATE_BY,
               CREATE_DATE
              ) values (v_investor_credit_id,v_credit_type_code,v_credit_no,v_investor_type_code,v_investor_name,p_create_user,sysdate);

               --插入客户开户详情表
               select sys_guid() into v_investor_detail_id from dual;
               insert into busi_investor_detail
                (ID,
                 COMPANY_ID,
                 CREDIT_ID,
                 CREDIT_TYPE,
                 CREDIT_NO,
                 NAME,
                 INVESTOR_TYPE,
                 LEGAL_PERSON,
                 HANDLE_PERSON,
                 CREATE_BY,
                 CREATE_DATE
                )
                values
                (v_investor_detail_id,p_companyid,v_investor_credit_id,v_credit_type_code,v_credit_no,v_investor_name,v_investor_type_code,
                 v_legal_person,v_handel_person,p_create_user,sysdate
                );

               --插入客户与私募公司关联表
               select sys_guid() into v_mgr_customer_id from dual;

               insert into busi_mgr_customer(
                  ID,
                  COMPANY_ID,
                  CREDIT_ID
                ) values (
                  v_mgr_customer_id,
                  p_companyid,
                  v_investor_credit_id
                );

            end if;

           --2.旧客户
           if v_kh_count >0 then
            select c.id into v_investor_credit_id  from busi_investor_credit c where c.credit_type = v_credit_type_code and c.credit_no = v_credit_no and c.is_delete = 0;
            select count(*) into v_investor_detail_count from busi_investor_detail d where d.credit_type = v_credit_type_code and d.credit_no = v_credit_no and d.company_id = p_companyid;

            --没有客户详情，就插入
              if v_investor_detail_count =0 then
                select sys_guid() into v_investor_detail_id from dual;
                select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                 insert into busi_investor_detail
                  (ID,
                   COMPANY_ID,
                   CREDIT_ID,
                   CREDIT_TYPE,
                   CREDIT_NO,
                   NAME,
                   INVESTOR_TYPE,
                   LEGAL_PERSON,
                   HANDLE_PERSON,
                   APPLY_NO,
                   CREATE_BY,
                   CREATE_DATE
                  )
                  values
                  (v_investor_detail_id,p_companyid,v_investor_credit_id,v_credit_type_code,v_credit_no,v_investor_name,v_investor_type_code,
                   v_legal_person,v_handel_person,v_apply_no,p_create_user,sysdate
                  );

               select count(*) into v_mgr_customer_count from busi_mgr_customer c where c.company_id = p_companyid and c.credit_id = v_investor_credit_id;
               --关联基金公司
               if v_mgr_customer_count = 0 then
                 select sys_guid() into v_mgr_customer_id from dual;

                 insert into busi_mgr_customer(
                    ID,
                    COMPANY_ID,
                    CREDIT_ID
                  ) values (
                    v_mgr_customer_id,
                    p_companyid,
                    v_investor_credit_id
                  );
               end if;
              else
                  select d.id into v_investor_detail_id from busi_investor_detail d where d.credit_type = v_credit_type_code and d.credit_no = v_credit_no and d.company_id = p_companyid;
              end if;
            end if;

           --插入银行账号信息
           select sys_guid() into v_bank_card_id from dual;
           select r.id into v_province_id from busi_region r where r.name like v_province_name||'%' and r.parent_id is null;
           select r.id into v_city_id from busi_region r where r.name like v_city_name||'%' and r.parent_id is not null;

           insert into busi_bind_bank_card(
              ID,
              CREDIT_ID,
              PRODUCT_ID,
              COMPANY_ID,
              USER_NAME,
              ACCOUNT_NO,
              OPEN_BANK_NAME,
              PROVINCE_ID,
              PROVINCE_NAME,
              CITY_ID,
              CITY_NAME,
              BIND_DATE,
              IS_EXAMINE
            ) values (
              v_bank_card_id,
              v_investor_credit_id,
              p_productid,
              p_companyid,
              v_bank_account_name,
              v_bank_accunt_no,
              v_open_bank_name,
              v_province_id,
              v_province_name,
              v_city_id,
              v_city_name,
              sysdate,
              '1'
            );

           --插入订单数据
           --生成订单编号
            select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_order_no from dual;
           select d.value into v_business_type from sys_dict d where d.type = 'sheet_business_type' and d.label = v_business_type_name;

           insert into BUSI_SHEET(
              ID,
              SHEET_NO,
              PT_ID,
              DT_ID,
              CREDIT_ID,
              COMPANY_ID,
              BANK_CARD_ID,
              SHEET_CREATE_TIME,
              APPLY_AMOUNT,
              MANAGER_CONTRACT_STATUS,
              INVESTOR_CONTRACT_STATUS,
              TRUSTEE_CONTRACT_STATUS,
              FUND_IS_RECEIVE,
              STATUS,
              MANAGER_FUND_CONFIRM,
              BUSINESS_TYPE,
              CREATE_BY,
              CREATE_DATE
            ) values (
              sys_guid(),
              v_order_no,
              p_productid,
              v_investor_detail_id,
              v_investor_credit_id,
              p_companyid,
              v_bank_card_id,
              v_apply_date,
              v_amount,
              '1',
              '1',
              '1',
              '1',
              '1',
              '1',
              v_business_type,
              p_create_user,
              sysdate
            );

            --改变导入销售数据临时表的状态为已处理v_sale_data_id
            update busi_sale_data d set d.status = '1' where d.id = v_sale_data_id;

       end loop;
     close data_cur;
     v_msg :='生成数据成功';
     open c_result for select p_flag as flag,'success' as res, v_msg as msg from dual;
     commit;


        --r_flag := 'faile';
        --r_msg := v_msg;
end sale_data_order;
/

