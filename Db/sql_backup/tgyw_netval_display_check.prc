create or replace procedure smzj.tgyw_netval_display_check is

---- *************************************************************************
-- SUBSYS:     托管服务
-- PROGRAM:      tgyw_netval_display_check
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  管理人净值  提供净值披露情况检查逻辑
-- 1. 检索日期范围为基金成立日起3个月内。如当日日期为20150113则，检索从20141013日到当日日期范围内，
-- 所有产品需要披露净值而未披露并且延期天数大于两个工作日的日期信息列表（信息包括产品名、产品代码、管理人、应披露净值日期）。
--延期天数大于两个工作日：披露日T日的净值数据，应该在T+2日（两个工作日后）披露。
-- 如：周一运行该逻辑，则检索上周四（前两个工作日）之前的净值（从基金成立日开始的3个月内），在披露频率设置的披露日期是否有披露净值。
 -- 其中基金成立日，如平台设置了，则取平台设置的成立日，否则取TA系统的基金成立日。
--2、在每日下午6点净值同步后自动执行该逻辑，将结果列表发送到指定邮箱。执行结果逻辑平台可检索。检索结果可根据管理人、应披露净值日期、产品代码排序
--3、邮件内容，只列出未正常披露的产品的信息，只包含最早的一条未披露记录。内容包括：产品名、产品代码、管理人、应披露净值日期

-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

v_count integer;
v_count_2 integer;
v_count_3 integer;
v_msg   varchar2(4000);
v_job_name varchar2(100) :='zsta' ;
v_job_log_name varchar2(100) :='zsta :' || '净值披露情况检查逻辑' ;
v_fund_id   integer;
v_fund_code varchar2(16);
v_fund_rq varchar2(16);
v_fund_jztbzq    integer;
v_currenr_date  varchar2(8);
v_fund_clr  varchar2(32);
v_fund_un_pl_fund_value  varchar2(50);
v_year      varchar2(4) := '2014';
v_fund_name busi_product.name%type;
v_fund_firstcode varchar2(1);
v_fund_substr varchar2(16);
v_fund_new varchar2(16);
v_fund_tgr_2 varchar2(16);
v_id varchar2(32);

cursor fundinfo_cur is select t.id,t.publish_date, t.product_no, t.public_net_period,t.name  from busi_product t  where t.is_validate = 1;
cursor minus_rq_fund_cur is   select t.pt_no,t.born_date from busi_public_netval_date_tmp t minus  select v.PRODUCT_NO,v.NET_VAL_DATE from busi_public_netval v ;

begin
 select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name and t.job_status = 1;

   if v_count > 0  then
    v_msg :='任务执行中，不允许重复执行，返回！';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
    return;
  end if;

  --锁定
  update t_fund_job_status t set t.job_status = 1 where t.job_en_name = v_job_name;
  commit;
  execute immediate 'truncate table busi_public_netval_date_tmp';


  open fundinfo_cur;
  loop
    fetch fundinfo_cur into v_fund_id,v_fund_clr, v_fund_code, v_fund_jztbzq,v_fund_name;
    if fundinfo_cur%notfound then
      exit;
    end if;


    --净值同步规则
    --1-同步成立日、开放期净值；
    --2-同步成立日、开放期、每月最后一个工作日；
    --3-同步成立日、开放期、每周最后一个工作日；
    --4-同步每一个工作日;
    --5-每季度最后一个工作日
    v_currenr_date := to_char(sysdate,'yyyyMMdd');

if trim(v_fund_clr) is not null then

     if v_fund_jztbzq = 1 then
            insert into busi_public_netval_date_tmp(pt_no,born_date,pt_id)
              select v_fund_code,rq,v_fund_id from (select v_fund_clr as rq from dual
                  union
                select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1'
                and t.rq <= v_currenr_date and t.rq>= v_fund_clr
             );


      end if;

     if v_fund_jztbzq = 2 then
         insert into busi_public_netval_date_tmp(pt_no,born_date,pt_id)
           select v_fund_code,rq,v_fund_id from (
                 select v_fund_clr as rq from dual
                     union
                select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1'
                and t.rq <= v_currenr_date and t.rq>= v_fund_clr
                union
                    --每月最后一个工作日
                       select max(a.rq) as rq from zsta.rlb@ta_dblink a where  a.gzr = '1' and a.rq <= v_currenr_date and a.rq>= v_fund_clr   group by substr(rq, 1, 6)
           );


      end if;


     if v_fund_jztbzq = 3 then
         insert into busi_public_netval_date_tmp(pt_no,born_date,pt_id)
           select v_fund_code,rq,v_fund_id from (
                 select v_fund_clr as rq from dual
                     union

                select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_currenr_date and t.rq>= v_fund_clr
                union
        --每周最后一个工作日
                select max(rq)as rq from zsta.rlb@ta_dblink a where gzr = '1'  and a.rq <= v_currenr_date and a.rq>= v_fund_clr  group by  NEXT_DAY(to_date(a.rq, 'yyyymmdd'),'星期一')
           );


     end if;


     if v_fund_jztbzq = 4 then
         insert into busi_public_netval_date_tmp(pt_no,born_date,pt_id)
           select v_fund_code,rq,v_fund_id from (
              select rq  from zsta.rlb@ta_dblink t where gzr='1' and t.rq <= v_currenr_date and t.rq>= v_fund_clr    and substr(rq, 1, 4) >= v_year
           );


     end if;


     if v_fund_jztbzq = 5 then
         insert into busi_public_netval_date_tmp(pt_no,born_date,pt_id)
           select v_fund_code,rq,v_fund_id from (
                 select max(rq) as rq from zsta.rlb@ta_dblink t where  gzr = '1' and t.rq <= v_currenr_date and t.rq>= v_fund_clr and substr(rq,5,2) in ('03','06','09','12') group by substr(rq, 1, 6)
           );


     end if;

end if;




  end loop;
  close fundinfo_cur;
  commit;
  --得到 应该净值的日期，去和净值数据表比对,去差值，如果和日历表的数据大于2天就输入数据表。如果没有净值，那么判断是否大约两天


   execute immediate 'truncate table T_FUND_UNDOPL_LIST';

 open minus_rq_fund_cur;
  loop
    fetch minus_rq_fund_cur into  v_fund_code,v_fund_rq;
    if minus_rq_fund_cur%notfound then
      exit;
    end if;

    select count(*) into v_count from zsta.rlb@ta_dblink t where t.gzr =1 and t.rq >= v_fund_rq and to_date(t.rq,'yyyy-mm-dd') < trunc(sysdate);
     if v_count > 0  then
       --插入到数据中
        insert into busi_pt_undisplay(pt_no,netval_date,netval_syn_period,pt_name,trust_man,PT_TYPE,pt_publish_date,cp_id,cp_name,Create_Date,Delay_day)
          select t.product_no,v_fund_rq as JZRQ,t.PUBLIC_NET_PERIOD,t.name,t.TRUSTEESHIP_INSTI,t.PRODUCT_TYPE,t.PUBLISH_DATE,t.cp_id,c.cp_name,sysdate,v_count from busi_product t left join busi_company c on t.cp_id=c.id where t.product_no=v_fund_code;
     end if;


  end loop;
  close minus_rq_fund_cur;
  commit;

 --处理最近两天的数据
       v_msg :='取日期成功,下一步做fund value ';
   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
 open fundinfo_cur;
  loop
    fetch fundinfo_cur into   v_fund_id,v_fund_clr, v_fund_code, v_fund_jztbzq,v_fund_name;
    if fundinfo_cur%notfound then
      exit;
    end if;

    select substr(v_fund_code, 0, 1) into v_fund_firstcode from dual;
    if v_fund_firstcode != 'S' then
      select substr(v_fund_code, 0, length(v_fund_code)-1) into v_fund_substr from dual;
      v_fund_new := 'S' || v_fund_substr;
      select count(*) into v_count_3 from busi_trust_netval where pt_no=v_fund_new;
      if v_count_3>0 then
        select trust_man into v_fund_tgr_2 from busi_trust_netval where pt_no=v_fund_new;
        update busi_trust_netval set trust_man=v_fund_tgr_2 where pt_no=v_fund_code;
       end if;
    end if;

    if trim(v_fund_clr) is null then
            select count(*) into v_count from busi_trust_netval where pt_no= v_fund_code;
            if v_count<1 then
               select sys_guid() into v_id from dual;
                  insert into busi_trust_netval(id,create_date,pt_no,pt_name,update_date,undisplay_date)values(v_id,sysdate,v_fund_code,v_fund_name,sysdate,'没有成立日期');
            else
                 update busi_trust_netval  set undisplay_date='没有产品成立日' where pt_no=v_fund_code;
             end if;

    else
        select count(*) into v_count from busi_trust_netval where pt_no= v_fund_code;
         if  v_count <1  then
                select sys_guid() into v_id from dual;
                insert   into busi_trust_netval(id,create_date,pt_no,pt_name,update_date,pt_publish_date)values(v_id,sysdate,v_fund_code,v_fund_name,sysdate,v_fund_clr);
         else
                  select count(*) into v_count_2 from ( select *  from ( select pt_no,netval_date ,rank() over(partition by pt_no order by netval_date desc ) rd from busi_pt_undisplay  ) a WHERE a.rd <3 ) c   where c.pt_no=v_fund_code ;
                  if v_count_2>0 then
                       select wm_concat(netval_date) into v_fund_un_pl_fund_value from ( select *  from ( select pt_no,netval_date ,rank() over(partition by pt_no order by netval_date desc ) rd from busi_pt_undisplay  ) a WHERE a.rd <3 ) c   where c.pt_no=v_fund_code ;
                       update busi_trust_netval  set undisplay_date=v_fund_un_pl_fund_value,pt_publish_date=v_fund_clr  where pt_no=v_fund_code;

                  else
                         update busi_trust_netval  set pt_publish_date=v_fund_clr  where pt_no=v_fund_code;
                  end if ;
        end if;


     end if ;



  end loop;
  close fundinfo_cur;
  commit;


    --释放
  update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
    v_msg :='同步成功！';
   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
  commit;


exception
    when others then
      rollback;
      v_msg :='同步失败，原因：'|| sqlcode || ':' || sqlerrm || '  ' ||v_fund_code || ' ' ||v_fund_name;
      insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);


end tgyw_netval_display_check;
/

