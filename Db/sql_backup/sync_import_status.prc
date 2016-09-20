create or replace procedure smzj.SYNC_IMPORT_STATUS
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_APPLY_DATA
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步 ta状态。 包括未导入ta， 已导入Ta， TA漏单 
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
-- AUTHOR:       xiaxiaonan
-- CREATE DATE:  2016-02-17
-- VERSION:
-- EDIT HISTORY: 
-- *************************************************************************
is
-- 以下字段从TA的表中获取
v_zh_sqdh       varchar2(100 char);                   --帐户申请，申请单号
v_zh_khbh       varchar2(100 char);                   --账户申请，客户编号
v_zh_ywlx       varchar2(100 char);                    --账户申请，业务类型
v_zh_jggr       varchar2(100 char);                    --账户申请，机构个人
v_zh_zjlx       varchar2(100 char);                    --账户申请，证件类型
v_zh_zjhm       varchar2(100 char);                    --账户申请，证件号码
v_zh_khmc       varchar2(100 char);                    --账户申请，客户名称
v_zh_djzh       varchar2(100 char);                    --账户申请，登记账号
v_zh_count      varchar2(100 char);                    --账户申请总数
v_count2        integer;                              --等于某个申请单号的账户申请总数 
v_zh_sqrq       varchar2(100 char);                     --账户申请，申请日期
     
v_jy_sqdh       varchar2(100 char);                   --交易申请，申请单号
v_jy_cpdm       varchar2(100 char);                    --交易申请，产品代码
v_jy_ywlx       varchar2(100 char);                    --交易申请，业务类型
v_jy_sqje       varchar2(100 char);                    --交易申请，申请金额
v_jy_sqfe       varchar2(100 char);                    --交易申请，申请份额
v_jy_count      integer;                              --交易申请总数
v_count1        integer;                              --等于某个申请单号的交易申请总数      
                                          
--以下字段从私募之家表中获取
v_BUSI_TYPE     varchar2(100 char);                    --账户申请，业务类型
v_USER_TYPE       varchar2(100 char);                  --账户申请，机构个人
v_CREDIT_TYPE     varchar2(100 char);                  --账户申请，证件类型
v_CREDIT_TYPE_CODE    varchar2(100 char);             --账户申请，证件类型代码
v_CREDIT_NO        varchar2(100 char);                --账户申请，证件号码
v_NAME           varchar2(100 char);                  --账户申请，姓名
v_REGIST_ACCOUNT  varchar2(100 char);                 --账户申请，登记账号

v_PT_NO         varchar2(100 char);                    --交易申请，产品代码
v_BUSINESS_TYPE varchar2(100 char);                    --交易申请，业务类型
v_APPLY_AMOUNT  varchar2(100 char);                    --交易申请，申请金额
v_APPLY_SHARE   varchar2(100 char);                    --交易申请，申请份额
--记录状态信息
v_msg1           varchar2(100 char);                   --记录TA状态信息
v_msg1_info      varchar2(1000 char);                   --记录TA状态详细信息
v_msg           varchar2(1000 char);                   --记录日志信息
v_flag  varchar2(1 char);
v_job_name varchar2(100):= 'SYNC_IMPORT_STATUS';
v_currdate       varchar2(100 char);                     --当前工作日
v_predate        varchar2(100 char);                    --上个工作日

--获取ut_sm_jysq表中申请日期为当天的数据
cursor trade_cur is
select jy.SQDH,jy.CPDM,case jy.YWLX when '申购' then '022' when '认购' then '020' when '赎回' then '024' else '029' end,
       to_char(jy.SQJE,'fm9999999990.00'),to_char(jy.SQFE,'fm9999999990.00')
from zsta.ut_sm_jysq@ta_dblink jy
where SQRQ = v_predate;

--增加申请日期,获取TA账户申请表中大于前一个工作日的数据 modify 20160331
cursor count_cur is
select zh.SQDH,zh.KHBH,case zh.YWLX when '开户' then '001' when '增开账户' then '008' when '修改资料' then '003' end ,
       case zh.JGGR when '个人' then '1' when '机构' then '2' end,
       zh.ZJLX,zh.ZJHM,zh.KHMC,zh.DJZH,zh.SQRQ
from zsta.ut_sm_zhsq@ta_dblink zh
where SQRQ >= v_predate;

begin
  --v_predate:='20160128';
  select to_char(sysdate,'yyyyMMdd') into v_currdate from dual;
  select getpreworkday(v_currdate)into v_predate from dual;     
  
  
  --先判断T+1日,TA中有没有相关的数据
  select count(*) into v_jy_count from  zsta.ut_sm_jysq@ta_dblink jy where SQRQ = v_predate;
  if v_jy_count = 0 then  
     return;
  end if;
  
  --账户申请可能存在申请日期>=创建日期的订单,modify 20160330
  select count(*) into v_zh_count from  zsta.ut_sm_zhsq@ta_dblink zh where SQRQ >= v_predate;
  if v_zh_count = 0 then
    return;
  end if;
  

  --先把私募之家T日申请全部设置为漏单
  update busi_sheet set ta_status = '导入漏单' where to_char(SHEET_CREATE_TIME,'yyyyMMdd')=v_predate;
  update busi_investor_detail set ta_status = '导入漏单' where to_char(CREATE_DATE,'yyyyMMdd')>=v_predate; 
  

  open trade_cur;
  loop
       fetch trade_cur into v_jy_sqdh,v_jy_cpdm,v_jy_ywlx,v_jy_sqje,v_jy_sqfe;
       if trade_cur%notfound then
           exit;
        end if;
        
        --用cursor中的TA单号来更新状态,如果私募之家中不存在该单号，说明为存疑数据
        select count(*) into v_count1 from busi_sheet where sheet_no = v_jy_sqdh and is_delete = '0';
        if v_count1 > 0 then                          --count1>0表示在私募之家中存在该申请单号
           select PT_NO,BUSINESS_TYPE,to_char(APPLY_AMOUNT,'fm9999999990.00'),to_char(APPLY_SHARE,'fm9999999990.00') into v_PT_NO,v_BUSINESS_TYPE,v_APPLY_AMOUNT,v_APPLY_SHARE from busi_sheet 
                  where sheet_no = v_jy_sqdh;
                  
             v_flag:='0';
             v_msg1_info:='';
             --产品代码不符
             --if v_jy_cpdm <> v_PT_NO then
             if compare(v_jy_cpdm,v_PT_NO)=0 then 
                v_msg1_info := v_msg1_info||'产品代码不符';
                v_flag:='1';
             end if;
             --业务类型不符
             --if v_jy_ywlx <> v_BUSINESS_TYPE then
             if compare(v_jy_ywlx,v_BUSINESS_TYPE)=0 then
                v_msg1_info :=v_msg1_info|| '业务类型不符';
                v_flag:='1';
             end if;
             --申请份额不符
             --if v_jy_sqje <> v_APPLY_AMOUNT then
             if compare(v_jy_sqje,v_APPLY_AMOUNT)=0 then 
               v_msg1_info := v_msg1_info||'申请份额不符';
               v_flag:='1';
              end if;
              --申请金额不符
              --if v_jy_sqfe<>v_APPLY_SHARE  then
              if compare(v_jy_sqfe,v_APPLY_SHARE)=0 then   
                v_msg1_info := v_msg1_info||'申请金额不符';
                v_flag:='1';
              end if;
               if v_flag='0' then
                 v_msg1 := '导入成功';
               else
                 v_msg1 := '数据不符';   
               end if;
             update busi_sheet set ta_status = v_msg1,ta_status_info=v_msg1_info where sheet_no = v_jy_sqdh;
         else                                --私募之家中没有该数据，则插入到私募之家中，并标记为存疑数据
               select count(*) into v_count1 from busi_sheet where sheet_no = v_jy_sqdh;   --私募之家中删除状态为1，而TA中有该申请数据
               if v_count1=0 then 
                  insert into busi_sheet (ID,SHEET_NO,PT_ID,PT_NO,BUSINESS_TYPE,APPLY_AMOUNT,APPLY_SHARE,is_delete,ta_status,SHEET_CREATE_TIME)
                         values (id_seq.nextval,v_jy_sqdh,id_seq.nextval,v_jy_cpdm,v_jy_ywlx,v_jy_sqje,v_jy_sqfe,'1','存疑数据',to_date(v_predate,'yyyyMMdd'));
               else
                  update busi_sheet set ta_status = '存疑数据' where sheet_no = v_jy_sqdh;
               end if;
        end if;  
     end loop;
     close trade_cur;
     
     
     open count_cur;
     loop
       fetch count_cur into v_zh_sqdh,v_zh_khbh,v_zh_ywlx,v_zh_jggr,v_zh_zjlx,v_zh_zjhm,v_zh_khmc,v_zh_djzh,v_zh_sqrq;
       if count_cur%notfound then
           exit;
        end if;
        
        --用cursor中的TA单号来更新状态,如果私募之家中不存在该单号，说明为存疑数据。申请日期必须要大于等于上一个工作日，modify 20160330
        select count(*) into v_count2 from busi_investor_detail where apply_no = v_zh_sqdh  
               and to_char(create_date,'yyyyMMdd') >= v_predate  and is_delete='0';
        if v_count2 > 0 then
           select BUSI_TYPE,INVESTOR_TYPE,CREDIT_TYPE,CREDIT_NO,NAME,REGIST_ACCOUNT
                  into v_BUSI_TYPE,v_USER_TYPE,v_CREDIT_TYPE_CODE,v_CREDIT_NO,v_NAME,v_REGIST_ACCOUNT
           from busi_investor_detail 
           where apply_no = v_zh_sqdh; 
           --私募之家中证件类型是以代码的形式存储
           select label into v_CREDIT_TYPE from sys_dict where type = 'credit_type' and value = v_CREDIT_TYPE_CODE;
          
           --对比客户编号
            v_flag:='0';
            v_msg1_info:='';
            /*
            --if v_CUSTOM_NO<>v_zh_khbh  then
            if compare(v_CUSTOM_NO,v_zh_khbh)=0 THEN
              v_msg1_info :=v_msg1_info||'客户编号不符';
              v_flag:='1';
            end if;
            */
            --对比业务类型
            --if v_BUSI_TYPE<>v_zh_ywlx  then
            if compare(v_BUSI_TYPE,v_zh_ywlx)=0 THEN
              v_msg1_info :=v_msg1_info||'业务类型不符';
              v_flag:='1';
            end if;
            --对比机构个人类型
            --if v_USER_TYPE<>v_zh_jggr  then
            if compare(v_USER_TYPE,v_zh_jggr)=0 THEN
              v_msg1_info :=v_msg1_info||'机构个认类型不符';
              v_flag:='1';
            end if;
            --对比证件类型
            --if v_CREDIT_TYPE<>v_zh_zjlx  then
            if compare(v_CREDIT_TYPE,v_zh_zjlx)=0 THEN
              v_msg1_info :=v_msg1_info||'证件类型不符';
              v_flag:='1';
            end if;
            --对比证件号码
            --if v_CREDIT_NO<>v_zh_zjhm  then
            if compare(v_CREDIT_NO,v_zh_zjhm)=0 THEN
              v_msg1_info :=v_msg1_info||'证件号码不符';
              v_flag:='1';
            end if;
            --对比客户名称
            --if v_NAME<>v_zh_khmc  then
            if compare(v_NAME,v_zh_khmc)=0 THEN
              v_msg1_info :=v_msg1_info||'客户名称不符';
              v_flag:='1';
            end if;
            --对比登记账号
            --if v_REGIST_ACCOUNT<>v_zh_djzh  then
            --如果私募之家里的等级账号为空，则不对比等级账号
            if compare(v_REGIST_ACCOUNT,null) = 0 then           
                if compare(v_REGIST_ACCOUNT,v_zh_djzh)=0 THEN
                  v_msg1_info :=v_msg1_info||'登记账号不符';
                  v_flag:='1';
                end if;
            end if;
     
            if v_flag='0' then
               v_msg1 := '导入成功';
            else
              v_msg1:= '数据不符';
            end if;
            update busi_investor_detail set ta_status = v_msg1,ta_status_info=v_msg1_info where apply_no = v_zh_sqdh;
      
          else                                --私募之家中没有该数据，则插入到私募之家中，并标记为存疑数据
             select count(*) into v_count1 from busi_investor_detail where apply_no = v_zh_sqdh;   --私募之家中删除状态为1，而TA中有该申请数据
             if v_count1=0 then 
                insert into busi_investor_detail (ID,apply_no,ta_status,busi_type,is_delete,company_id,credit_id,create_date)
                       values (id_seq.nextval,v_zh_sqdh,'存疑数据',v_zh_ywlx,'1',id_seq.nextval,id_seq.nextval,to_date(v_zh_sqrq,'yyyy-MM-dd,HH24:mi:ss'));
             else
                update busi_investor_detail set ta_status = '存疑数据' where apply_no = v_zh_sqdh;
             end if;
       end if;  
     end loop;
     close count_cur;
     
     insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,'更新成功');
     commit;
     
EXCEPTION
    when others then
        if trade_cur%isopen then
            close trade_cur;
        end if;
        if count_cur%isopen then
            close count_cur;
        end if;
        
        rollback;
        v_msg :='更新失败，原因：' || sqlcode || ':' || sqlerrm ||' '|| SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_IMPORT_STATUS;
/

