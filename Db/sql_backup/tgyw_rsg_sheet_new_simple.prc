create or replace procedure smzj.tgyw_rsg_sheet_new_simple(
                                                      p_batch_number_id in varchar2,
                                                      p_company_id in varchar2,
                                                      p_product_id in varchar2,
                                                      p_create_date   in varchar2,
                                                      p_create_by in varchar2,
                                                      p_is_mgr in varchar2,
                                                      p_mgr_id in varchar2,
                                                      c_result out sys_refcursor) is

---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_rsg_sheet_new_simple
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       guxu
-- DESCRIPTION:  批量导入认/申购订单(去银行账户版)
-- CREATE DATE:  2016-4-11
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

  v_job_name varchar2(100) :='tgyw_rsg_sheet_new_simple';
  v_count integer;--记录已经生成数据条数
  v_limit_count integer;--记录产品是否有限制
  v_trade_count integer;--记录已经生成数据条数
  v_tody_time  varchar2(10 char);

  v_kh_count integer; --是否存在客户表t_fund_cust中
  v_khsq_count integer; --是否存在客户表t_fund_khsq中
  v_fundcomp_count integer;--是否关联基金公司
  v_msg varchar2(6000 char);--返回信息
  v_flag integer :=0;--标志本地证件号码对应的名称与TA的名称是否一致

  v_legal_person busi_sale_data.legal_person %type;--法人代表姓名
  v_handel_person busi_sale_data.handel_person%type;--经办人姓名

  v_rgje busi_sale_data.amount%type;--认购金额

  v_investor_type busi_sale_data.investor_type%type;--个人机构
  v_user_type CHAR(1);

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

  v_credit_type_code  varchar2(50);--证件类型编码
  v_pt_status_count number; --是否有基金开放日
  v_start_price  VARCHAR2(128); --认申购起点
  v_current_date date; --当前时间
  v_buy_count number; --购买次数
  v_son_buy_monther varchar2(50 char); --子买母返回值
  v_product_id varchar2(50);--产品id
  v_apply_date varchar2(50);--申请时间
  v_sql_data   varchar2(2014);
  v_sql_check   varchar2(2014);
  type myrefcur is ref cursor;
  data_cur myrefcur;
  data_cur_check myrefcur;
  v_same_apply_date_count integer;--记录同一申请日期录数
  v_same_apply_date_str varchar2(2014);--记录申请日期
  v_credit_company_count integer;--用户和公司关系记录数

begin
  v_flag:=0;
    select count(*) into v_count from busi_sale_data t  where t.status = 1  and t.company_id = p_company_id and to_char(t.create_date, 'yyyy-MM-dd') = p_create_date and bank_no is null;
    if v_count > 0 then
        v_msg := '今天'||p_create_date||'已自动生成过数据，不能再次生成。';
         open c_result for select v_job_name as flag,'faile' as res, v_msg as msg from dual;
        return;
    end if;
   
  if p_product_id is not null and p_product_id!='-1' then
   --查询该批次中的申请日期是否有确认数据
   select count(*) into v_same_apply_date_count from busi_sale_data t1 where exists (select to_char(t2.apply_date,'yyyy-MM-dd') from busi_sale_data t2 where t2.product_id=p_product_id and t2.batch_number_id = p_batch_number_id and t1.status=1 and to_char(t1.apply_date,'yyyy-MM-dd') = to_char(t2.apply_date,'yyyy-MM-dd') and t1.product_id=t2.product_id and t1.bank_no is null group by to_char(t2.apply_date,'yyyy-MM-dd'));
   if v_same_apply_date_count >0 then
     select wmsys.wm_concat(tb.apply_date) into v_same_apply_date_str from (select distinct to_char(t1.apply_date,'yyyy-MM-dd') apply_date from busi_sale_data t1 where exists (select to_char(t2.apply_date,'yyyy-MM-dd') from busi_sale_data t2  where t2.product_id=p_product_id and t2.batch_number_id = p_batch_number_id and t1.status=1 and to_char(t1.apply_date,'yyyy-MM-dd') = to_char(t2.apply_date,'yyyy-MM-dd') and t1.product_id=t2.product_id and t1.bank_no is null group by to_char(t2.apply_date,'yyyy-MM-dd'))) tb;
     v_msg := '该批数据中存在申请日期'||v_same_apply_date_str||'已自动生成过数据，不能再次生成。';
     open c_result for select v_job_name as flag,'faile' as res, v_msg as msg from dual;
     return;
   end if;
  
    select count(*) into v_hasimportdata from busi_sale_data t  where t.status = 0  and t.company_id = p_company_id  and t.batch_number_id = p_batch_number_id and t.product_id = p_product_id and  to_char(t.create_date, 'yyyy-MM-dd') = p_create_date;
  else
   --查询该批次中的申请日期是否有确认数据
   select count(*) into v_same_apply_date_count from busi_sale_data t1 where exists (select to_char(t2.apply_date,'yyyy-MM-dd') from busi_sale_data t2 where t2.batch_number_id = p_batch_number_id  and t1.status=1 and to_char(t1.apply_date,'yyyy-MM-dd') = to_char(t2.apply_date,'yyyy-MM-dd') and t1.product_id=t2.product_id and t1.bank_no is null group by to_char(t2.apply_date,'yyyy-MM-dd'));
   if v_same_apply_date_count >0 then
     select wmsys.wm_concat(tb.apply_date) into v_same_apply_date_str from (select distinct to_char(t1.apply_date,'yyyy-MM-dd') apply_date from busi_sale_data t1 where exists (select to_char(t2.apply_date,'yyyy-MM-dd') from busi_sale_data t2  where t2.batch_number_id = p_batch_number_id and t1.status=1 and to_char(t1.apply_date,'yyyy-MM-dd') = to_char(t2.apply_date,'yyyy-MM-dd') and t1.product_id=t2.product_id and t1.bank_no is null group by to_char(t2.apply_date,'yyyy-MM-dd'))) tb;
     v_msg := '该批次数据中存在申请日期'||v_same_apply_date_str||'已自动生成过数据，不能再次生成。';
     open c_result for select v_job_name as flag,'faile' as res, v_msg as msg from dual;
     return;
   end if;
    
    select count(*) into v_hasimportdata from busi_sale_data t  where t.status = 0  and t.company_id = p_company_id  and t.batch_number_id = p_batch_number_id and  to_char(t.create_date, 'yyyy-MM-dd') = p_create_date;
  end if;
    if v_hasimportdata <=0 then
        v_msg :='无导入数据，请先导入';
        open c_result for select v_job_name as flag,'faile' as res, v_msg as msg from dual;
        return;
    end if;

    --检查数据合法性
   select to_char(trunc(sysdate),'yyyy-mm-dd' ) into v_tody_time from dual;

   if p_is_mgr is not null and p_is_mgr='0' then
      v_sql_data:='select t.investor_name,t.credit_no,t.credit_type_code,t.legal_person,t.handel_person,t.amount,t.investor_type,t.id,t.product_id,
        to_char(t.apply_date,'||'''yyyy-MM-dd'''||') from busi_sale_data t join busi_product p on t.product_id=p.id join busi_product_authorization pa on p.id = pa.product_id where t.status = 0 and pa.mgr_id =''' || p_mgr_id ||''' and t.batch_number_id=''' ||p_batch_number_id || ''' and t.company_id =''' ||p_company_id || ''' and to_char(t.create_date,'||'''yyyy-MM-dd'''||') = ''' ||p_create_date || '''';
      v_sql_check:='select t.investor_name,t.credit_no,t.credit_type_code from busi_sale_data t join busi_product p on t.product_id=p.id join busi_product_authorization pa on p.id = pa.product_id where t.status = 0 and pa.mgr_id = ''' || p_mgr_id ||''' and t.batch_number_id=''' ||p_batch_number_id || ''' and t.company_id = ''' ||p_company_id || ''' and to_char(t.create_date, '||'''yyyy-MM-dd'''||') = ''' ||p_create_date || '''';
   else
      v_sql_data:='select t.investor_name,t.credit_no,t.credit_type_code,t.legal_person,t.handel_person,t.amount,t.investor_type,t.id,t.product_id,
        to_char(t.apply_date,'||'''yyyy-MM-dd'''||') from busi_sale_data t where t.status = 0 and t.batch_number_id=''' ||p_batch_number_id || ''' and t.company_id =''' ||p_company_id || ''' and to_char(t.create_date,'||'''yyyy-MM-dd'''||') = ''' ||p_create_date || '''';
      v_sql_check:='select t.investor_name,t.credit_no,t.credit_type_code from busi_sale_data t  where t.status = 0 and t.batch_number_id=''' ||p_batch_number_id || ''' and t.company_id = ''' ||p_company_id || ''' and to_char(t.create_date, '||'''yyyy-MM-dd'''||') = ''' ||p_create_date || '''';
   end if;
   if p_product_id is not null and p_product_id!='-1' then
      v_sql_check:=v_sql_check|| ' and t.product_id =''' ||p_product_id || '''';
      v_sql_data:=v_sql_data|| ' and t.product_id =''' ||p_product_id || '''';
   end if;

 open data_cur_check for v_sql_check;
    loop
        fetch data_cur_check into v_investor_name ,v_credit_no,v_credit_type_code;
        if data_cur_check%notfound then
            exit;
        end if;

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
        fetch data_cur into v_investor_name,v_credit_no,v_credit_type_code,v_legal_person,v_handel_person,v_rgje,v_investor_type,v_tab_id,v_product_id,v_apply_date;
        if data_cur%notfound then
          exit;
        end if;

    v_rg_je_ta:=null;
    v_sh_je_ta:=null;
    v_rsh_je_ta:=null;
    
    select to_date(v_apply_date ||to_char(sysdate,'HH24:MI:SS' ),'yyyy-MM-ddHH24:MI:SS'  ) into v_current_date from dual;
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
                -- 查一次是否有其他公司开户
                select count(*) into v_khsq_count from busi_investor_credit cr where cr.id = v_credit_id  and cr.is_delete='0' and cr.regist_account is not null;
                select sys_guid() into v_khsqid from dual;
                select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;
                -- 插入开户记录，其中 业务类型  001  开户  008 增加交易账户
                insert into busi_investor_detail(id,investor_type,handle_person,legal_person,name,create_by,busi_type,company_id,apply_no,create_date,credit_type,credit_id,credit_no,manage_fee_mark,achieve_fee_mark,pt_id)
                   values(v_khsqid,v_user_type,v_handel_person,v_legal_person,v_investor_name,p_create_by,(case when v_khsq_count>0 then '008' else '001' end),p_company_id,v_apply_no,v_current_date,v_credit_type_code,v_credit_id,v_credit_no,'是','是',v_product_id);
                select count(*) into v_fundcomp_count from  busi_credit_company t where t.credit_id=v_credit_id  and t.company_id=p_company_id;
                --关联基金公司
                if v_fundcomp_count = 0 then
                       insert into busi_credit_company (credit_id,company_id,sqrq) values(v_credit_id,p_company_id,v_current_date);
                 end if;

                  UPDATE busi_investor_credit t SET t.SOURCETYPE='0',t.is_delete='0' WHERE  id=v_credit_id;
                  UPDATE BUSI_CREDIT_COMPANY c SET c.SOURCETYPE='0',c.insti_name='直销,'||c.insti_name,c.sqrq=v_current_date WHERE c.credit_id=v_credit_id AND c.company_id=p_company_id;
            else--2016.6.27 杨伟 添加用户公司关系
                select count(*) into v_credit_company_count from busi_credit_company where credit_id=v_credit_id and company_id=p_company_id;
                if v_credit_company_count = 0 then
                     insert into busi_credit_company (credit_id,company_id,sqrq) values(v_credit_id,p_company_id,v_current_date);
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

        select count(1) into v_buy_count from busi_sheet t where t.credit_id=v_credit_id and t.pt_id=v_product_id and t.business_type in('020','022')  and to_char(t.sheet_create_time,'yyyy-MM-dd')  = v_apply_date  and t.is_delete='0' ;
            if v_buy_count> 0 then
               v_flag:=1;
               v_msg := v_msg||'证件号码：'||v_credit_no||',姓名：'||v_investor_name||',已经在【'||v_apply_date|| '】认购、申购过此产品,不需要重新录入;'||'<br>';
            end if;

        --查询基金状态
        select t.publish_status,t.is_limit_buy,start_price,t.product_no,name into  v_publish_status,v_is_limit_buy,v_start_price,v_product_no,v_product_name from busi_product t  where t.id=v_product_id;
        --本地是发行状态，则类型为认购，本地不是发行状态则根据产品代码与日期去TA查询基金状态，非发行则全为申购
        if (v_publish_status='1' or v_publish_status='2')  then
              v_busi_type :='认购';
              v_busi_type_code :='020';
        elsif ( v_publish_status='0'  or v_publish_status='6')  then  -- 0 正常交易，6 （停止赎回）可申购
            v_busi_type :='申购';
            v_busi_type_code :='022';
        else
           -- select t.jjzt into v_publish_status from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm =v_product_no and t.rq=to_date(v_apply_date,'yyyy-MM-dd');
            begin
                select t.jjzt,1 into v_publish_status,v_pt_status_count from t_rlb_jjzt t where t.jjdm =v_product_no and t.rq = to_char(to_date(v_apply_date,'yyyy-MM-dd'),'yyyyMMdd');
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
                v_msg := '产品:' || v_product_name || ' 在日期' || v_apply_date || '不是临时开放日，不能导入订单';
            end if;

        end if;

         --认申购额度做限制的时候
        if v_is_limit_buy=1 then
             --认购最低金额
            if v_busi_type_code='020' then       -- 认购
                  select count(1) into  v_trade_count  from busi_sheet  t where  t.credit_id=v_credit_id and t.pt_id = v_product_id and  t.business_type = v_busi_type_code  and t.is_delete='0';
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

                    select count(1) into  v_trade_count  from busi_sheet  t where  t.credit_id=v_credit_id and t.pt_id = v_product_id and  t.business_type in('020','022')  and t.is_delete='0';
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
            select (substr(to_char(sysdate,'yyyyMMddhh24mmss'),0,14) || cast(dbms_random.value(10000000,99999999) as int)) into v_apply_no from dual;--生成申请单号
            select sys_guid() into v_table_id from dual;
            --插入交易申请表busi_sheet.导入时做了转换，这里不需要在转换
            -- select round(v_rgje*10000,6) into v_ex_rgje from dual;--认购金额扩大10000倍，保留6位小数

            --获取投资人详情id
            if(v_khsqid is null) then
                select d.id into v_khsqid from busi_investor_detail d where d.credit_id=v_credit_id and  company_id = p_company_id and  is_delete='0' and rownum=1;
            end if;

            insert into busi_sheet(id,sheet_no,sheet_create_time,business_type,pt_id,pt_no,apply_amount,credit_id,create_by,company_id,
               manager_contract_status,investor_contract_status,trustee_contract_status,fund_is_receive,status,manager_fund_confirm,create_date,bank_card_id,dt_id,is_simple
            ) values (v_table_id,v_apply_no,v_current_date,v_busi_type_code,v_product_id,v_product_no,v_rgje,v_credit_id,p_create_by,
               p_company_id, '1','1', '1',  '1', '1', '1',sysdate,'',v_khsqid,'1');

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
 end tgyw_rsg_sheet_new_simple;
/

