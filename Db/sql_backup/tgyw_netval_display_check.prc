create or replace procedure smzj.tgyw_netval_display_check is

---- *************************************************************************
-- SUBSYS:     �йܷ���
-- PROGRAM:      tgyw_netval_display_check
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- AUTHOR:       liujian
-- DESCRIPTION:  �����˾�ֵ  �ṩ��ֵ��¶�������߼�
-- 1. �������ڷ�ΧΪ�����������3�����ڡ��統������Ϊ20150113�򣬼�����20141013�յ��������ڷ�Χ�ڣ�
-- ���в�Ʒ��Ҫ��¶��ֵ��δ��¶�������������������������յ�������Ϣ�б���Ϣ������Ʒ������Ʒ���롢�����ˡ�Ӧ��¶��ֵ���ڣ���
--���������������������գ���¶��T�յľ�ֵ���ݣ�Ӧ����T+2�գ����������պ���¶��
-- �磺��һ���и��߼�������������ģ�ǰ���������գ�֮ǰ�ľ�ֵ���ӻ�������տ�ʼ��3�����ڣ�������¶Ƶ�����õ���¶�����Ƿ�����¶��ֵ��
 -- ���л�������գ���ƽ̨�����ˣ���ȡƽ̨���õĳ����գ�����ȡTAϵͳ�Ļ�������ա�
--2����ÿ������6�㾻ֵͬ�����Զ�ִ�и��߼���������б��͵�ָ�����䡣ִ�н���߼�ƽ̨�ɼ�������������ɸ��ݹ����ˡ�Ӧ��¶��ֵ���ڡ���Ʒ��������
--3���ʼ����ݣ�ֻ�г�δ������¶�Ĳ�Ʒ����Ϣ��ֻ���������һ��δ��¶��¼�����ݰ�������Ʒ������Ʒ���롢�����ˡ�Ӧ��¶��ֵ����

-- CREATE DATE:  2015-10-23
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************

v_count integer;
v_count_2 integer;
v_count_3 integer;
v_msg   varchar2(4000);
v_job_name varchar2(100) :='zsta' ;
v_job_log_name varchar2(100) :='zsta :' || '��ֵ��¶�������߼�' ;
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
    v_msg :='����ִ���У��������ظ�ִ�У����أ�';
    insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
    return;
  end if;

  --����
  update t_fund_job_status t set t.job_status = 1 where t.job_en_name = v_job_name;
  commit;
  execute immediate 'truncate table busi_public_netval_date_tmp';


  open fundinfo_cur;
  loop
    fetch fundinfo_cur into v_fund_id,v_fund_clr, v_fund_code, v_fund_jztbzq,v_fund_name;
    if fundinfo_cur%notfound then
      exit;
    end if;


    --��ֵͬ������
    --1-ͬ�������ա������ھ�ֵ��
    --2-ͬ�������ա������ڡ�ÿ�����һ�������գ�
    --3-ͬ�������ա������ڡ�ÿ�����һ�������գ�
    --4-ͬ��ÿһ��������;
    --5-ÿ�������һ��������
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
                    --ÿ�����һ��������
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
        --ÿ�����һ��������
                select max(rq)as rq from zsta.rlb@ta_dblink a where gzr = '1'  and a.rq <= v_currenr_date and a.rq>= v_fund_clr  group by  NEXT_DAY(to_date(a.rq, 'yyyymmdd'),'����һ')
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
  --�õ� Ӧ�þ�ֵ�����ڣ�ȥ�;�ֵ���ݱ�ȶ�,ȥ��ֵ�����������������ݴ���2����������ݱ����û�о�ֵ����ô�ж��Ƿ��Լ����


   execute immediate 'truncate table T_FUND_UNDOPL_LIST';

 open minus_rq_fund_cur;
  loop
    fetch minus_rq_fund_cur into  v_fund_code,v_fund_rq;
    if minus_rq_fund_cur%notfound then
      exit;
    end if;

    select count(*) into v_count from zsta.rlb@ta_dblink t where t.gzr =1 and t.rq >= v_fund_rq and to_date(t.rq,'yyyy-mm-dd') < trunc(sysdate);
     if v_count > 0  then
       --���뵽������
        insert into busi_pt_undisplay(pt_no,netval_date,netval_syn_period,pt_name,trust_man,PT_TYPE,pt_publish_date,cp_id,cp_name,Create_Date,Delay_day)
          select t.product_no,v_fund_rq as JZRQ,t.PUBLIC_NET_PERIOD,t.name,t.TRUSTEESHIP_INSTI,t.PRODUCT_TYPE,t.PUBLISH_DATE,t.cp_id,c.cp_name,sysdate,v_count from busi_product t left join busi_company c on t.cp_id=c.id where t.product_no=v_fund_code;
     end if;


  end loop;
  close minus_rq_fund_cur;
  commit;

 --����������������
       v_msg :='ȡ���ڳɹ�,��һ����fund value ';
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
                  insert into busi_trust_netval(id,create_date,pt_no,pt_name,update_date,undisplay_date)values(v_id,sysdate,v_fund_code,v_fund_name,sysdate,'û�г�������');
            else
                 update busi_trust_netval  set undisplay_date='û�в�Ʒ������' where pt_no=v_fund_code;
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


    --�ͷ�
  update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
    v_msg :='ͬ���ɹ���';
   insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);
  commit;


exception
    when others then
      rollback;
      v_msg :='ͬ��ʧ�ܣ�ԭ��'|| sqlcode || ':' || sqlerrm || '  ' ||v_fund_code || ' ' ||v_fund_name;
      insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_log_name,v_msg);


end tgyw_netval_display_check;
/

