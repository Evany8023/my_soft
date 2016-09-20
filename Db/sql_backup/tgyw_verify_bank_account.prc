create or replace procedure smzj.TGYW_VERIFY_BANK_ACCOUNT(p_company_id in varchar2,   --公司id
                                                     p_BATCH_NUMBER_ID in varchar2, --批次号
                                                     p_apply_date in varchar2,      --申请日期
                                                     p_mgrid in varchar2,      --管理人id
                                                     p_ismgr in varchar2,      --是否一级管理人
                                                     p_flag2 out varchar2,
                                                     p_message out varchar2) is

---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      TGYW_VERIFY_BANK_ACCOUNT
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       xiaxn
-- DESCRIPTION:  验证银行账号
-- CREATE DATE:  2016-05-05
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
v_ID                varchar2(100);           --临时表id
v_NO                varchar2(100);           --行号
v_INVESTOR_TYPE     varchar2(100);           --投资人类型，取自busi_bank_data_temp表
v_CREDIT_TYPE       varchar2(100);           --投资人证件类型
v_CREDIT_NO         varchar2(100);           --投资人证件号码
v_CREDIT_ID         varchar2(100);           --投资人id
v_INVESTOR_NAME     varchar2(100);           --投资人姓名
v_PROVINCE_NAME     varchar2(100);           --开户行省份
v_CITY_NAME         varchar2(100);           --开户行城市
v_OPEN_BANK_NAME    varchar2(100);           --开户行
v_PRODUCT_NO        varchar2(100);           --产品代码
v_IS_BACK_ACCOUNT   varchar2(100);           --是否分红赎回账号


v_ACCOUNT_NO        varchar2(100);           --账号
v_USER_NAME         varchar2(100);           --开户名称,取自busi_bind_bank_card表
v_USER_NAME2        varchar2(100);           --开户名称，取自busi_investor_credit表
v_USER_TYPE         varchar2(100);           --投资人类型，取自busi_investor_credit表
v_PRODUCT_ID        varchar2(100);           --产品id
v_flag              number;                  --单条数据校验成功失败标志
v_msg               varchar2(1000);          --单条数据校验信息
v_count             number;
v_msg2              varchar2(1000);          --赎回分红账号详细信息

v_count2            number:=0;                  --计数信息，当错误等于10条时，不在增加错误p_message的值

v_msg3              varchar2(1000):='TGYW_VERIFY_BANK_ACCOUNT';
v_job_name varchar2(100) :='sync_old_fund_value';


cursor data_cur is select t.id,t.row_number,CASE t.INVESTOR_TYPE when '个人' then '1' ELSE '2' END,
                t.CREDIT_TYPE_CODE,t.CREDIT_NO,t.investor_name,t.province_name,t.city_name,t.open_bank_name,t.PRODUCT_NO,t.IS_BACK_ACCOUNT
       from busi_bank_data_temp t
       where t.BATCH_NUMBER_ID =  p_BATCH_NUMBER_ID and t.is_delete = '0' AND t.COMPANY_ID=p_company_id AND t.APPLY_DATE=p_apply_date order by t.row_number;


begin
  p_flag2:= 0;                 --初始化为0，表示没有错误


  open data_cur;
  loop
      fetch data_cur into v_ID,v_NO,v_INVESTOR_TYPE,v_CREDIT_TYPE,v_CREDIT_NO,v_INVESTOR_NAME,v_PROVINCE_NAME,v_CITY_NAME,v_OPEN_BANK_NAME,v_PRODUCT_NO,v_IS_BACK_ACCOUNT;
        if data_cur%notfound then
          exit;
        end if;

        v_flag:=0;
        v_msg:='文件第'||v_NO||'行：'||' ';


        --1.判断产品是否存在
        IF v_flag=0 then
            select count(1) into v_count from busi_product p where p.product_no = v_PRODUCT_NO and is_delete='0';
            if v_count =0 then
                v_flag:='1';
                v_msg := v_msg||'产品'||v_PRODUCT_NO||'不存在，请核实修改后再次导入';
            else
                select p.id into v_PRODUCT_ID from busi_product p where  p.product_no = v_PRODUCT_NO and p.is_delete = '0'; --取出产品id
            end if;
        END IF;

        --2.判断产品是否属于这家公司
        IF v_flag=0 then
            select count(1) into v_count from busi_product p where  p.cp_id = p_company_id and p.product_no=v_PRODUCT_NO  and p.is_delete = '0';
            if v_count=0 then
                v_flag:='1';
                v_msg := v_msg||'产品'||v_PRODUCT_NO||'不属于该管理人，请核实修改后再次导入';
            end if;
        END IF;

        --如果是二级管理员，判断是否是授权的产品
        IF v_flag=0 and p_ismgr=0 then
             select count(1) into v_count from busi_product_authorization p  where p.product_id=v_PRODUCT_ID and p.mgr_id=p_mgrid and p.cp_id=p_company_id;
             if v_count=0 then
                v_flag:='1';
                v_msg := v_msg||'您无权操作产品'||v_PRODUCT_NO||'，请核实修改后再次导入';
             end if;
         END IF;


        --3.判断投资人类型，投资人证件类型，投资人证件号码,投资人姓名是否一致
        IF v_flag=0 then
            select count(1) into v_count from busi_investor_credit t where  t.credit_type = v_CREDIT_TYPE and t.credit_no = v_CREDIT_NO  and is_delete=0;
            if v_count=0 then
                   v_flag:=1;
                   v_msg := v_msg||'找不到该投资人，请检查证件类型和证件号码，核实修改后再次导入';
            else
                   select t.id into v_CREDIT_ID from busi_investor_credit t where t.credit_type = v_CREDIT_TYPE and t.credit_no = v_CREDIT_NO;   --取出credit_id
            end if;
            --校验投资人类型和投资人姓名
            if v_flag=0 then
                 select t.name,t.user_type into v_USER_NAME2,v_USER_TYPE from busi_investor_credit t where t.credit_type = v_CREDIT_TYPE and  t.credit_no = v_CREDIT_NO  and is_delete=0;
                 if v_USER_NAME2 <> v_INVESTOR_NAME then
                        v_flag:=1;
                        v_msg := v_msg||'投资人名字不正确，请核实修改后再次导入';
                 end if;
                 if v_USER_TYPE <> v_INVESTOR_TYPE then
                        v_flag:=1;
                        v_msg := v_msg||'投资人类型不正确，请核实修改后再次导入';
                 end if;
             end if;
        END IF;

        --4.判断投资人是否属于这家公司
        IF v_flag=0 then
            select count(1) into v_count from busi_credit_company c where  c.company_id = p_company_id and c.credit_id=v_CREDIT_ID;
            if v_count=0 and v_flag=0 then
                  v_flag:='1';
                  v_msg := v_msg||'客户'||v_INVESTOR_NAME||'不属于该管理人，请先于‘新增客户’中添加该客户';
            end if;
         END IF;


        --5.校验开户行名称，开户行省份和开户行城市
        IF v_flag=0 then
            select count(1) into v_count from busi_region where name like '%'||v_PROVINCE_NAME||'%';
            if v_count=0 then
                  v_flag:='1';
                  v_msg := '省份信息'||v_PROVINCE_NAME||'错误，请核实修改后再次导入';
            end if;

            select count(1) into v_count from busi_region where name like  '%'||v_CITY_NAME||'%';
            if v_count=0 and v_flag=0 then
                  v_flag:='1';
                  v_msg := '城市信息'||v_CITY_NAME||'错误，请核实修改后再次导入';
            end if;
        END IF;

      IF v_flag=1 then  --校验正确，检查赎回分红账号
           p_flag2 := 1;
           if v_count2 < 10 then
               p_message := p_message||v_msg||chr(13);
           end if;
           v_count2 := v_count2+1;
           delete busi_bank_data_temp t where t.batch_number_id=p_BATCH_NUMBER_ID and t.company_id=p_company_id;
           return;
       END IF;

      --判断是否已经存在分红赎回账号
      select count(1) into v_count from busi_bind_bank_card b where b.credit_id= v_CREDIT_ID and b.is_back_account='1' and b.product_id = v_PRODUCT_ID and is_delete='0';
      if v_count = 0 then                 --没有赎回分红账号
         update busi_bank_data_temp t set t.REMARK = '无' where t.id = V_ID;
      else
         select c.OPEN_BANK_NAME,c.ACCOUNT_NO,USER_NAME into v_OPEN_BANK_NAME,v_ACCOUNT_NO,v_USER_NAME  from busi_bind_bank_card c
                where c.credit_id= v_CREDIT_ID and c.is_back_account='1' and c.product_id = v_PRODUCT_ID and c.is_delete='0';
         v_msg2 :=  '开户行：'||v_OPEN_BANK_NAME||'，账户：'||v_ACCOUNT_NO||'，开户名称：'||v_USER_NAME;
         update busi_bank_data_temp t set t.REMARK = '已有赎回分红账号',t.REMARK_INFO = v_msg2 where t.id = v_ID;
      end if;

   end loop;
   close data_cur;
   --调试记录每行校验信息，写完要注释掉。
   if v_flag=0 then
      p_message := '校验成功';
      update busi_bank_data_temp t set t.check_result = v_flag, t.check_info=v_msg where t.row_number=v_NO;
   end if;
   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg3);
   commit;
EXCEPTION
    when others then
        if data_cur%isopen then
            close data_cur;
        end if;
        rollback;

        v_msg3 :='同步失败，原因：' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg3);
        commit;


end TGYW_VERIFY_BANK_ACCOUNT;
/

