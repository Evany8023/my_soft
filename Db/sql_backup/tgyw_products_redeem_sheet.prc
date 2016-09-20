create or replace procedure smzj.tgyw_products_redeem_sheet(p_company_id in varchar2, --公司ID
                                                      p_product_id in varchar2, --产品ID
                                                      p_ismgr in varchar2,  --是否一级管理人
                                                      p_mgrid in varchar2,  --管理人ID
                                                      p_create_by in varchar2,  --创建人
                                                      todaydate   in varchar2,   --当天
                                                      c_result out sys_refcursor) is  --返回结果

---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_products_redeem_sheet
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       卢雅琴
-- DESCRIPTION:  (多产品录单)批量赎回确认数据

-- CREATE DATE:   2016-06-07
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

  v_job_name varchar2(100) :='tgyw_products_redeem_sheet';
  v_count integer;--记录已经生成数据条数
  v_kh_count integer; --是否存在客户表t_fund_cust中
  v_shfh_count integer; --是否存在客户表t_fund_cust中

  v_msg varchar2(4000 char);--返回信息
  v_tzrlx busi_batch_redeem_tmp.investor_type_no%type;--投资人类型编号
  v_zjlb busi_batch_redeem_tmp.credit_type%type;--证件类别
  v_djzh busi_investor_credit.regist_account%type;--证件类别
  v_zjlbcode busi_batch_redeem_tmp.credit_type_no%type;--证件代码
  v_tzrxm busi_batch_redeem_tmp.investor_name%type;--投资者姓名
  v_zjhm busi_batch_redeem_tmp.credit_no%type;--证件号码
  v_id busi_batch_redeem_tmp.id%type ;--产品成立表id
  v_credit_id busi_investor_credit.id%type; --客户证件ID
  v_fundcode busi_batch_redeem_tmp.product_no%type;--产品代码
  v_comcode busi_batch_redeem_tmp.company_no%type;--公司代码
  v_hasimportdata integer :=1;--判断是否有导入数据
  v_shfe busi_batch_redeem_tmp.redeem_share%type; --赎回份额
  v_tzrxm_ta varchar2(255 char);--ta投资者姓名
  v_flag integer;
  v_sqdh  varchar2(50 char);--申请单号
  v_total_feye     number(16,4);      -- 份额余额
  v_input_total_feye     number(16,4);      -- 份额余额
  v_bank_card_id varchar2(32);             --银行卡id
  v_tzrxq_id busi_investor_detail.id%type;   --投资人详情id
  v_current_time VARCHAR2(128); --当前时间
  v_current_date date; --当前时间
  v_son_buy_monther varchar2(50 char); --子买母返回值
  v_apply_date busi_batch_redeem_tmp.apply_date%type; --申请日期
  v_product_id busi_batch_redeem_tmp.product_id%type; --产品id
  v_sql_cur varchar2(2014);--数据集SQL
  v_sql_check varchar2(2014);--数据集SQL
  type myrefcur  is  ref  cursor;
  data_cur myrefcur;  --定义赎回数据游标
  data_cur_check myrefcur;  --定义赎回数据游标

begin
    --是一级管理人
    if (p_ismgr is not null and p_ismgr='0') then
    v_sql_cur:='select t.investor_name,t.credit_no,t.credit_type_no,t.credit_type,t.id,t.investor_type_no,t.product_no,t.company_no,t.redeem_share,t.apply_date,t.product_id
      from busi_batch_redeem_tmp t join busi_product_authorization pa on t.product_id = pa.product_id
      where t.company_id='''||p_company_id||''' and pa.mgr_id='''||p_mgrid||''' and t.BATCH_NUMBER_ID like '''|| todaydate||'%'' and t.status=0';

    v_sql_check:='select t.INVESTOR_NAME,t.CREDIT_NO,t.CREDIT_TYPE_NO
      from busi_batch_redeem_tmp t
      where t.company_id='''||p_company_id||''' and t.BATCH_NUMBER_ID like '''|| todaydate||'%'' and t.status=0';
    else
    v_sql_cur:='select t.investor_name,t.credit_no,t.credit_type_no,t.credit_type,t.id,t.investor_type_no,t.product_no,t.company_no,t.redeem_share,t.apply_date,t.product_id
      from busi_batch_redeem_tmp t
      where t.company_id='''||p_company_id||''' and t.BATCH_NUMBER_ID like '''|| todaydate||'%'' and t.status=0';

    v_sql_check:='select t.INVESTOR_NAME,t.CREDIT_NO,t.CREDIT_TYPE_NO
      from busi_batch_redeem_tmp t
      where t.company_id='''||p_company_id||''' and t.BATCH_NUMBER_ID like '''|| todaydate||'%'' and t.status=0';
    end if;

    --产品id为空
    if p_product_id is not null then
      v_sql_cur:=v_sql_cur|| ' and t.product_id =''' ||p_product_id || '''';
      v_sql_check:=v_sql_check|| ' and t.product_id =''' ||p_product_id || '''';
    end if;

    v_flag:=0;

    open data_cur_check for v_sql_check;
    loop
        fetch data_cur_check into v_tzrxm ,v_zjhm,v_zjlbcode;
        if data_cur_check%notfound then
            exit;
        end if;

        begin
            select t.name into v_tzrxm_ta from busi_investor_credit t where t.credit_no = v_zjhm and t.credit_type=v_zjlbcode  group by t.name;
        exception  when others then
             v_tzrxm_ta :='';
        end;

        if trim(v_tzrxm_ta) <> trim(v_tzrxm) then
            v_flag :=1;
            v_msg := v_msg||'证件号码('|| v_zjhm||')对应的投资人姓名('|| v_tzrxm ||')与平台('||v_tzrxm_ta||')不匹配;<br>';
        end if ;
    end loop;
    close data_cur_check;

    if v_flag = 1 then
        open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
        return ;
    end if ;



   --产品id不为空(开始)
   --插入表操作start
   if p_product_id is not null then
   -- 删除批量导入赎回
   open data_cur for v_sql_cur;
    loop
        fetch data_cur into v_tzrxm,v_zjhm,v_zjlbcode,v_zjlb,v_id,v_tzrlx,v_fundcode,v_comcode,v_shfe,v_apply_date,v_product_id;
        if data_cur%notfound then
          exit;
        end if;

        --验证是否已经生成过
        select count(*)  into v_count  from busi_batch_redeem_tmp t
         where  t.COMPANY_ID = p_company_id   and t.PRODUCT_ID = p_product_id  and to_char(t.APPLY_DATE, 'yyyy-MM-dd') = to_char(v_apply_date, 'yyyy-MM-dd') and t.status = '1'  ;
         if v_count > 0 then
          v_flag :=1;
          v_msg := '指定产品'||v_fundcode||'申请日期'||to_char(v_apply_date,'yyyy-MM-dd')||'已自动生成过数据，不能再次生成;<br>';
         end if;

        --验证是否存在重复数据
        select count(*) into v_hasimportdata from  busi_batch_redeem_tmp t
         where   t.COMPANY_ID = p_company_id    and t.PRODUCT_ID = p_product_id  and t.BATCH_NUMBER_ID like todaydate ||'%' and t.status = '0' ;

        if v_hasimportdata =0 then
          v_msg :='无确认数据，请先导入';
          open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
          return;
        end if;

        select count(*) into v_count  from (
        select distinct CREDIT_NO,CREDIT_TYPE_NO,to_char(apply_date, 'yyyy-MM-dd')  from  busi_batch_redeem_tmp t
        where   t.COMPANY_ID = p_company_id    and t.PRODUCT_ID = p_product_id  and t.BATCH_NUMBER_ID like todaydate ||'%' and t.status = '0' );

        if v_hasimportdata !=v_count then
        v_flag :=1;
        v_msg :='数据(证件类型+证件号码+产品代码+申请日期）存在重复，请先确保数据不重复，再自动生成数据;<br>';
        end if;

        select count(*) into v_kh_count from busi_investor_credit t,busi_credit_company c
           where c.credit_id=t.id and t.credit_no = v_zjhm and t.credit_type = v_zjlbcode  and c.company_id = p_company_id and t.is_delete = '0';

        --如果不存在客户，
        if v_kh_count=0 then
            v_flag :=1;
            v_msg := v_msg||'此客户，证件号码('|| v_zjhm||') 没有开过户，请确认;<br>';

        end if;

        --存在客户
        if v_kh_count >0 then
            select t.id,t.regist_account  into v_credit_id,v_djzh from busi_investor_credit t
                 where  t.credit_type = v_zjlbcode  and  t.credit_no = v_zjhm  and t.is_delete= '0';
            if trim(v_djzh) is null then
                 v_flag :=1;
                 v_msg := v_msg||'此客户，证件号码('|| v_zjhm||') 没有Ta开过户成功，请确认;<br>';

            end if;
         end if;

            --查询份额余额  正式环境使用，测试环境注释
            --select sum(fundvolbalance) into v_total_feye  from  zsta_tgpt.bal_fund@ta_dblink   where fundcode=v_fundcode and taaccountid=v_djzh ;
            --查询份额余额  测试环境使用，正式环境注释

            select sum(balance) into v_total_feye from BUSI_SHARE_BALANCE where PT_NO = v_fundcode  and  REGIST_ACCOUNT = v_djzh ;

            if v_total_feye is null then
                 v_flag :=1;
                 v_msg := v_msg||'此客户，证件号码('|| v_zjhm||') 没有份额，请确认;<br>';
            end if;

            select child_buy_or_sale_prarent(v_credit_id,p_product_id,'02',null) into v_son_buy_monther from dual;
           if v_son_buy_monther='true' then
                 v_flag := '1';
                v_msg := v_msg||'投资人(''' ||v_zjhm ||''')申购子基金，会自动出发子基金申购母基金，请勿重复录单;';
           elsif v_son_buy_monther <> 'true' and  v_son_buy_monther <> 'false' then
              insert into t_fund_job_running_log (JOB_NAME,job_running_log) values ('子买母问题',v_son_buy_monther || '    '||v_credit_id || '    '|| p_product_id || v_apply_date );
           end  if;

             select count(id) into v_count from busi_sheet where  credit_id= v_credit_id and  pt_id = p_product_id  and to_char(sheet_create_time,'yyyy-MM-dd')=to_char(v_apply_date,'yyyy-MM-dd') and BUSINESS_TYPE='024' and is_delete='0';
            if v_count> 0 and v_flag = 0  then
                v_flag :=1;
                v_msg := v_msg||'此客户，证件号码('|| v_zjhm||')  已在申请日期:'||to_char(v_apply_date,'yyyy-MM-dd')||' 提交过该基金的赎回申请;';
           end if;

           if v_shfe='all' then
                 v_input_total_feye:=v_total_feye;
            elsif v_shfe is not null then
                 v_input_total_feye:= to_number(replace(v_shfe,',',''),'9999999999999999.9999');
            end if;

           if  v_input_total_feye > v_total_feye then
                 v_flag :=1;
                 v_msg := v_msg||'此客户，证件号码('|| v_zjhm||') 申请份额超过总份额，请联系管理员!;原因：总份额:'||v_total_feye||';';
           end if;

           select count(1) into v_shfh_count from busi_bind_bank_card b  where b.credit_id=v_credit_id and b.product_id=p_product_id and b.is_back_account = '1' and  is_delete='0'and rownum=1;
           if v_shfh_count < 1 then
                  v_flag :=1;
                 v_msg := v_msg||'此客户，证件号码('|| v_zjhm||')没有赎回分红银行账号，为顺利划拨款项，请先添加银行账号;';

           end if;


    select to_char(sysdate,'HH24:MI:SS' ) into v_current_time from dual;
   select to_date(to_char(v_apply_date,'yyyy-MM-dd' )||v_current_time,'yyyy-MM-ddHH24:MI:SS'  ) into v_current_date from dual;


          if    v_flag <> 1 then
                      --获取分红赎回账账户银行卡id
                      select b.id into v_bank_card_id from busi_bind_bank_card b  where b.credit_id=v_credit_id and b.product_id=p_product_id and b.is_back_account = '1' and  is_delete='0'and rownum=1;
                      select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_sqdh from dual;
                      --获取投资人详情id
                      select d.id into v_tzrxq_id from busi_investor_detail d where d.credit_id=v_credit_id and  company_id = p_company_id and  is_delete='0' and rownum=1;
                       --插入到订单
                      insert into busi_sheet(id,sheet_no,pt_id,pt_no,dt_id,bank_card_id,sheet_create_time,company_id,credit_id,business_type,apply_share,create_by,
                                          create_date,manager_contract_status,investor_contract_status,trustee_contract_status,fund_is_receive,status,manager_fund_confirm,is_delete)
                      values (sys_guid(),v_sqdh,p_product_id,v_fundcode,v_tzrxq_id,v_bank_card_id,v_current_date,p_company_id,v_credit_id,'024',v_input_total_feye,p_create_by,
                                          sysdate, '1','1', '1', '1', '1','1','0');
          end if;

    end loop;
    close data_cur;

    if v_flag = 1 then
        rollback;
        v_msg:=substr(v_msg,1,900);
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg  from dual;
    else
        update busi_batch_redeem_tmp t set status='1' where t.company_id=p_company_id and t.product_id=p_product_id  and to_char(t.create_date, 'yyyyMMdd') = todaydate;
        v_msg :='生成数据成功';
        open c_result for select v_job_name as flag,'success' as res, v_msg as msg from dual;
    end if ;

    insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
    --产品id不为空(结束)
    --产品id为空(开始)
    else
           --插入表操作start
    open data_cur for v_sql_cur;
    loop
        fetch data_cur into v_tzrxm,v_zjhm,v_zjlbcode,v_zjlb,v_id,v_tzrlx,v_fundcode,v_comcode,v_shfe,v_apply_date,v_product_id;
        if data_cur%notfound then
          exit;
        end if;

        --验证是否已经生成过
        select count(*)  into v_count  from busi_batch_redeem_tmp t
         where  t.COMPANY_ID = p_company_id   and t.PRODUCT_ID = v_product_id and to_char(t.APPLY_DATE, 'yyyy-MM-dd') = to_char(v_apply_date, 'yyyy-MM-dd') and t.status = '1'  ;
         if v_count > 0 then
          v_flag :=1;
          v_msg := '指定产品'||v_fundcode||'申请日期'||to_char(v_apply_date,'yyyy-MM-dd')||'已自动生成过数据，不能再次生成;';
         end if;

        --验证是否存在重复数据
        select count(*) into v_hasimportdata from  busi_batch_redeem_tmp t
         where   t.COMPANY_ID = p_company_id    and t.PRODUCT_ID = v_product_id  and t.BATCH_NUMBER_ID like todaydate ||'%'  and t.status = '0' ;

        if v_hasimportdata =0 then
          v_msg :='无确认数据，请先导入';
          open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
          return;
        end if;

        select count(*) into v_count  from (

        select distinct CREDIT_NO,CREDIT_TYPE_NO,to_char(apply_date, 'yyyy-MM-dd') from  busi_batch_redeem_tmp t
        where   t.COMPANY_ID = p_company_id    and t.PRODUCT_ID = v_product_id  and t.BATCH_NUMBER_ID like todaydate ||'%' and t.status = '0' );

        if v_hasimportdata !=v_count then
        v_flag :=1;
        v_msg :='数据(证件类型+证件号码+产品代码+申请日期）存在重复，请先确保数据不重复，再自动生成数据;';
        end if;

        select count(*) into v_kh_count from busi_investor_credit t,busi_credit_company c
           where c.credit_id=t.id and t.credit_no = v_zjhm and t.credit_type = v_zjlbcode  and c.company_id = p_company_id and t.is_delete = '0';

        --如果不存在客户，
        if v_kh_count=0 then
            v_flag :=1;
            v_msg := v_msg||'此客户，证件号码('|| v_zjhm||') 没有开过户，请确认;';

        end if;

        --存在客户
        if v_kh_count >0 then
            select t.id,t.regist_account  into v_credit_id,v_djzh from busi_investor_credit t
                 where  t.credit_type = v_zjlbcode  and  t.credit_no = v_zjhm  and t.is_delete= '0';
            if trim(v_djzh) is null then
                 v_flag :=1;
                 v_msg := v_msg||'此客户，证件号码('|| v_zjhm||') 没有Ta开过户成功，请确认;';

            end if;
         end if;

            --查询份额余额  正式环境使用，测试环境注释
            --select sum(fundvolbalance) into v_total_feye  from  zsta_tgpt.bal_fund@ta_dblink   where fundcode=v_fundcode and taaccountid=v_djzh ;
            --查询份额余额  测试环境使用，正式环境注释

            select sum(balance) into v_total_feye from BUSI_SHARE_BALANCE where PT_NO = v_fundcode  and  REGIST_ACCOUNT = v_djzh ;

            if v_total_feye is null then
                 v_flag :=1;
                 v_msg := v_msg||'此客户，证件号码('|| v_zjhm||') 没有份额，请确认;';
            end if;

            select child_buy_or_sale_prarent(v_credit_id,v_product_id,'02',null) into v_son_buy_monther from dual;
           if v_son_buy_monther='true' then
                 v_flag := '1';
                v_msg := v_msg||'投资人(''' ||v_zjhm ||''')申购子基金，会自动出发子基金申购母基金，请勿重复录单';
           elsif v_son_buy_monther <> 'true' and  v_son_buy_monther <> 'false' then
              insert into t_fund_job_running_log (JOB_NAME,job_running_log) values ('子买母问题',v_son_buy_monther || '    '||v_credit_id || '    '|| v_product_id || v_apply_date );
           end  if;

             select count(id) into v_count from busi_sheet where  credit_id= v_credit_id and  pt_id = v_product_id  and to_char(sheet_create_time,'yyyy-MM-dd')=to_char(v_apply_date,'yyyy-MM-dd') and BUSINESS_TYPE='024' and is_delete='0';
            if v_count> 0 and v_flag = 0  then
                v_flag :=1;
                v_msg := v_msg||'此客户，证件号码('|| v_zjhm||')  已在申请日期:'||to_char(v_apply_date,'yyyy-MM-dd')||' 提交过该基金的赎回申请' ||';';
           end if;

           if v_shfe='all' then
                 v_input_total_feye:=v_total_feye;
            elsif v_shfe is not null then
                 v_input_total_feye:= to_number(replace(v_shfe,',',''),'9999999999999999.9999');
            end if;

           if  v_input_total_feye > v_total_feye then
                 v_flag :=1;
                 v_msg := v_msg||'此客户，证件号码('|| v_zjhm||') 申请份额超过总份额，请联系管理员!;原因：总份额:'||v_total_feye||';';
           end if;

           select count(1) into v_shfh_count from busi_bind_bank_card b  where b.credit_id=v_credit_id and b.product_id=v_product_id and b.is_back_account = '1' and  is_delete='0'and rownum=1;
           if v_shfh_count < 1 then
                  v_flag :=1;
                 v_msg := v_msg||'此客户，证件号码('|| v_zjhm||')没有赎回分红银行账号，为顺利划拨款项，请先添加银行账号;';

           end if;


    select to_char(sysdate,'HH24:MI:SS' ) into v_current_time from dual;
   select to_date(to_char(v_apply_date,'yyyy-MM-dd' )||v_current_time,'yyyy-MM-ddHH24:MI:SS'  ) into v_current_date from dual;


          if    v_flag <> 1 then
                      --获取分红赎回账账户银行卡id
                      select b.id into v_bank_card_id from busi_bind_bank_card b  where b.credit_id=v_credit_id and b.product_id=v_product_id and b.is_back_account = '1' and  is_delete='0'and rownum=1;
                      select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_sqdh from dual;
                      --获取投资人详情id
                      select d.id into v_tzrxq_id from busi_investor_detail d where d.credit_id=v_credit_id and  company_id = p_company_id and  is_delete='0' and rownum=1;
                       --插入到订单
                      insert into busi_sheet(id,sheet_no,pt_id,pt_no,dt_id,bank_card_id,sheet_create_time,company_id,credit_id,business_type,apply_share,create_by,
                                          create_date,manager_contract_status,investor_contract_status,trustee_contract_status,fund_is_receive,status,manager_fund_confirm,is_delete)
                      values (sys_guid(),v_sqdh,v_product_id,v_fundcode,v_tzrxq_id,v_bank_card_id,v_current_date,p_company_id,v_credit_id,'024',v_input_total_feye,p_create_by,
                                          sysdate, '1','1', '1', '1', '1','1','0');
          end if;




    end loop;
    close data_cur;

    if v_flag = 1 then
        rollback;
        v_msg:=substr(v_msg,1,900);
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg  from dual;
    else
        update busi_batch_redeem_tmp t set status='1' where t.company_id=p_company_id and to_char(t.create_date, 'yyyyMMdd') = todaydate;
        v_msg :='生成数据成功';
        open c_result for select v_job_name as flag,'success' as res, v_msg as msg from dual;
    end if ;

    insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);

    end if;
    --产品id不为空(结束)

    commit;
    return;

    exception
        when others then
        begin
            rollback;
            DBMS_OUTPUT.put_line('sqlcode : '||sqlcode);
            DBMS_OUTPUT.put_line('sqlerror : '||sqlerrm);
            v_msg:= sqlcode||':'||sqlerrm ||'   '|| dbms_utility.format_error_backtrace();
            v_msg:=substr(v_msg,1,900);
            insert into t_fund_job_running_log (JOB_NAME,job_running_log) values (v_job_name,v_msg);
            open c_result for select v_job_name as flag, 'faile' as res, v_msg as msg from dual;
            commit;
            IF data_cur%ISOPEN  THEN  CLOSE data_cur; END IF;
            return;
        end ;
end tgyw_products_redeem_sheet;
/

