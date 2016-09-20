create or replace procedure smzj.sync_old_fund_value is

  v_count integer;
  v_msg   varchar2(4000);
  v_job_name varchar2(100) :='sync_old_fund_value';

  v_year      varchar2(4) := '2014';
  v_date      date;
  v_create_date varchar2(16);
  v_fund_id   varchar2(32 char );
  v_fund_name   varchar2(100 char );
  v_com_id   varchar2(32 char );
  v_fund_clr  varchar2(32);
  v_fund_code varchar2(16);
  v_fund_value_status integer :=1;
  v_type      integer;
  v_ya_day varchar2(16);
  --��ֵͬ�����ڣ�
  --0-��ͬ����
  --1-ͬ�������ա������ھ�ֵ��
  --2-ͬ�������ա������ڡ�ÿ�����һ�������գ�
  --3-ͬ�������ա������ڡ�ÿ�����һ�������գ�
  --4-ͬ��ÿһ��������;
  --5-ÿ�������һ��������
  v_fund_jztbzq    integer;
  v_fund_tzzjztbzq integer;
  v_fund_glrjztbzq integer;
  v_mf_code varchar(20 char);
  v_is_mocode_kfr_pl varchar(10 char );
  --������Ϣ
  cursor fundinfo_cur is
    select t.id, to_char(t.publish_date,'yyyyMMdd') as fund_clrq, t.product_no,t.public_net_period , t.invest_net_period,  t.mgr_net_period,t.is_close_master_net ,t.cp_id,t.name
      from busi_product t
     where t.is_validate=1
       and t.is_examine=1 ;
   --������Ϣ



  /**
  --1-ͬ�������ա������ھ�ֵ��
  cursor date_cur_1(fund_code varchar2,fund_clr varchar2,yearr varchar2) is
  --������
  select fund_clr as rq from dual union
  --������
  select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm=fund_code and  t.jjzt in('0','5','6') and t.gzr='1';

  --2-ͬ�������ա������ڡ�ÿ�����һ�������գ�
  cursor date_cur_2(fund_code varchar2,fund_clr varchar2,yearr varchar2) is
  --������
  select fund_clr as rq from dual union
  --������
  select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm=fund_code and  t.jjzt in('0','5','6') and t.gzr='1'
  union
  --ÿ�����һ��������
  select max(rq) as rq from zsta.rlb@ta_dblink where substr(rq, 1, 4) >= yearr and gzr = '1' group by substr(rq, 1, 6);

  --3-ͬ�������ա������ڡ�ÿ�����һ�������գ�
  cursor date_cur_3(fund_code varchar2,fund_clr varchar2,yearr varchar2) is
  --������
  select fund_clr as rq from dual union
  --������
  select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm=fund_code and  t.jjzt in('0','5','6') and t.gzr='1'
  union
  --ÿ�����һ��������
  select max(rq)as rq from zsta.rlb@ta_dblink t where substr(rq, 1, 4) >= yearr and gzr = '1' group by  NEXT_DAY(to_date(rq, 'yyyymmdd'),'����һ');

  --4-ͬ��ÿһ�������գ�
  cursor date_cur_4(fund_code varchar2,fund_clr varchar2,yearr varchar2) is
  --ÿһ��������
  select rq  from zsta.rlb@ta_dblink where gzr='1'  and substr(rq, 1, 4) >= yearr;

  --5-ÿ�������һ��������
  cursor date_cur_5(fund_code varchar2,fund_clr varchar2,yearr varchar2) is
  --ÿһ��������
  select max(rq) as rq from zsta.rlb@ta_dblink where substr(rq, 1, 4) >= yearr and gzr = '1' and substr(rq,5,2) in ('03','06','09','12') group by substr(rq, 1, 6);
  */

begin

  select count(*) into v_count from t_fund_job_status t where t.job_en_name = v_job_name and t.job_status = 1;

  if v_count > 0  then
    v_msg :='����ִ���У��������ظ�ִ�У�����!';
    insert into t_fund_job_running_log(job_name,job_running_log) values('��ֵͬ����ʱ����',v_msg);
    return;
  end if;

  --����
  update t_fund_job_status t set t.job_status = 1 where t.job_en_name = v_job_name;
  commit;

  select to_date('20140901','yyyymmdd') into v_date from dual;
  select to_char(sysdate,'yyyymmdd') into v_create_date from dual;

  execute immediate 'truncate table  t_fund_value_tmp';


  open fundinfo_cur;
  loop
    fetch fundinfo_cur
      into v_fund_id,v_fund_clr, v_fund_code, v_fund_jztbzq, v_fund_tzzjztbzq,v_fund_glrjztbzq,v_is_mocode_kfr_pl,v_com_id,v_fund_name;

    if fundinfo_cur%notfound then
      exit;
    end if;

     v_mf_code:=null;
     select count(1) into v_count from  zsta.fundstructuredinfo@ta_dblink  t where t.mfundcode is not null and  t.mfundcode <> '---' and t.mfundcode=v_fund_code;
     if v_count >0 then
          select  t.mfundcode into v_mf_code from  zsta.fundstructuredinfo@ta_dblink  t where t.mfundcode is not null and  t.mfundcode <> '---' and t.mfundcode=v_fund_code group by t.mfundcode;
      end if;

      select count(*) into v_count from zsta.fundextrainfo@ta_dblink t where  t.FUNDCODE=v_fund_code;
    if v_count >0 then
        select trim(applytype) into v_ya_day from zsta.fundextrainfo@ta_dblink t where  t.FUNDCODE=v_fund_code;
        if v_ya_day='2' then   --ֱ��ѹ��
          insert into    t_Fund_Value_Tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
          select tmp.fund_code,getPreWorkDay(tmp.fund_tradedate),tmp.type,tmp.fund_id,0,v_com_id,v_fund_name from t_Fund_Value_Tmp tmp where tmp.fund_code=v_fund_code  ;

        end if;
    end if;
    v_type := 1; -- ��¶��ֵͬ��
    ---ͬ�������ա������ھ�ֵ��
    if v_fund_jztbzq = 1  then
            insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
            select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (select v_fund_clr as rq from dual);
    end if;
  ----ͬ�������ա������ھ�ֵ��
    if v_fund_jztbzq = 2   then
          insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)   select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (
            select v_fund_clr as rq from dual
            union
            --ÿ�����һ��������
            select max(rq) as rq from zsta.rlb@ta_dblink where substr(rq, 1, 4) >= v_year and gzr = '1' and rq <= v_create_date group by substr(rq, 1, 6));
    end if;
   --ͬ�������ա������ڡ�ÿ�����һ�������գ�
    if v_fund_jztbzq = 3 then
          insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (
                select v_fund_clr as rq from dual union
                --������
                --ÿ�����һ��������
                select max(rq)as rq from zsta.rlb@ta_dblink t where substr(rq, 1, 4) >= v_year and gzr = '1' and t.rq <= v_create_date group by  NEXT_DAY(to_date(rq, 'yyyymmdd'),'����һ')
                );


    end if;
    ---ͬ��ÿһ��������;
    if v_fund_jztbzq = 4 then

      insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)

        select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (select rq  from zsta.rlb@ta_dblink where gzr='1' and rq <= v_create_date  and substr(rq, 1, 4) >= v_year);

    end if;
   --ÿ�������һ��������
    if v_fund_jztbzq = 5 then
            insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                select v_fund_code,rq,v_type,v_fund_id ,v_fund_value_status,v_com_id,v_fund_name from (
                select v_fund_clr as rq from dual
                union
                select max(rq) as rq from zsta.rlb@ta_dblink where substr(rq, 1, 4) >= v_year and gzr = '1' and rq <= v_create_date and substr(rq,5,2) in ('03','06','09','12') group by substr(rq, 1, 6)
             );

    end if;



      if v_mf_code is null and  v_is_mocode_kfr_pl = 0  then
              delete  t_fund_value_tmp t where t.fund_code= v_fund_code and t.type=v_type and  t.fund_tradedate in ( select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_create_date);
             if v_ya_day ='2' then
                 --������
                  insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                   select v_fund_code,getpreworkday( rq),v_type,v_fund_id,0,v_com_id,v_fund_name from(
                      select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_create_date
                    );
             else
                 insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                   select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from(
                 select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_create_date
                 );

             end if ;
           end if;



    v_type := 2;--Ͷ����ͬ��
     ---ͬ�������ա������ھ�ֵ��
    if v_fund_tzzjztbzq = 1 then
            insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
            select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (select v_fund_clr as rq from dual);
    end if;
  ----ͬ�������ա������ھ�ֵ��
    if v_fund_tzzjztbzq = 2 then
          insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)   select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (
            select v_fund_clr as rq from dual
            union
            --ÿ�����һ��������
            select max(rq) as rq from zsta.rlb@ta_dblink where substr(rq, 1, 4) >= v_year and gzr = '1' and rq <= v_create_date group by substr(rq, 1, 6));

    end if;
   --ͬ�������ա������ڡ�ÿ�����һ�������գ�
    if v_fund_tzzjztbzq = 3 then
          insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (
                select v_fund_clr as rq from dual union
                --������
                --ÿ�����һ��������
                select max(rq)as rq from zsta.rlb@ta_dblink t where substr(rq, 1, 4) >= v_year and gzr = '1' and t.rq <= v_create_date group by  NEXT_DAY(to_date(rq, 'yyyymmdd'),'����һ')
                );

    end if;
    ---ͬ��ÿһ��������;
    if v_fund_tzzjztbzq = 4 then

      insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
        select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (select rq  from zsta.rlb@ta_dblink where gzr='1' and rq <= v_create_date  and substr(rq, 1, 4) >= v_year);

    end if;
   --ÿ�������һ��������
    if v_fund_tzzjztbzq = 5 then
               insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                select v_fund_code,rq,v_type,v_fund_id ,v_fund_value_status,v_com_id,v_fund_name from (
                select v_fund_clr as rq from dual
                union
                select max(rq) as rq from zsta.rlb@ta_dblink where substr(rq, 1, 4) >= v_year and gzr = '1' and rq <= v_create_date and substr(rq,5,2) in ('03','06','09','12') group by substr(rq, 1, 6)
             );

    end if;



      if v_mf_code is null and  v_is_mocode_kfr_pl = 0  then
              delete  t_fund_value_tmp t where t.fund_code= v_fund_code and t.type=v_type and  t.fund_tradedate in ( select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_create_date);
             if v_ya_day ='2' then
                 --������
                  insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                   select v_fund_code,getpreworkday( rq),v_type,v_fund_id,0,v_com_id,v_fund_name from(
                      select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_create_date
                    );
             else
                 insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                   select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from(
                 select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_create_date
                 );

             end if ;
           end if;


    -- ������ ���� ͬ��
            v_type := 3;   --������ͬ��
    if v_fund_glrjztbzq = 1 then
            insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
            select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (select v_fund_clr as rq from dual);
    end if;
  ----ͬ�������ա������ھ�ֵ��
    if v_fund_glrjztbzq = 2 then
          insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)   select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (
            select v_fund_clr as rq from dual
            union
            --ÿ�����һ��������
            select max(rq) as rq from zsta.rlb@ta_dblink where substr(rq, 1, 4) >= v_year and gzr = '1' and rq <= v_create_date group by substr(rq, 1, 6));

    end if;
   --ͬ�������ա������ڡ�ÿ�����һ�������գ�
    if v_fund_glrjztbzq = 3 then
          insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (
                select v_fund_clr as rq from dual union
                --������
                --ÿ�����һ��������
                select max(rq)as rq from zsta.rlb@ta_dblink t where substr(rq, 1, 4) >= v_year and gzr = '1' and t.rq <= v_create_date group by  NEXT_DAY(to_date(rq, 'yyyymmdd'),'����һ')
                );
    end if;
    ---ͬ��ÿһ��������;
    if v_fund_glrjztbzq = 4 then

      insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
        select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from (select rq  from zsta.rlb@ta_dblink where gzr='1' and rq <= v_create_date  and substr(rq, 1, 4) >= v_year);

    end if;
   --ÿ�������һ��������
    if v_fund_glrjztbzq = 5 then
               insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                select v_fund_code,rq,v_type,v_fund_id ,v_fund_value_status,v_com_id,v_fund_name from (
                select v_fund_clr as rq from dual
                union
                select max(rq) as rq from zsta.rlb@ta_dblink where substr(rq, 1, 4) >= v_year and gzr = '1' and rq <= v_create_date and substr(rq,5,2) in ('03','06','09','12') group by substr(rq, 1, 6)
             );

   end if;

      if (v_mf_code is null and   v_is_mocode_kfr_pl = 0 )  and v_fund_glrjztbzq<> 0 then

         delete  t_fund_value_tmp t where t.fund_code= v_fund_code and t.type=v_type and  t.fund_tradedate in ( select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_create_date);

             if v_ya_day ='2' then
                 --������
                  insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                   select v_fund_code,getpreworkday( rq),v_type,v_fund_id,0,v_com_id,v_fund_name from(
                      select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_create_date
                    );
             else
                 insert into  t_fund_value_tmp(fund_code,fund_tradedate,type,fund_id,STATUS,CP_ID,fund_name)
                   select v_fund_code,rq,v_type,v_fund_id,v_fund_value_status,v_com_id,v_fund_name from(
                   select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_create_date
                 );

             end if ;
        end if;

  end loop;
  close fundinfo_cur;

  commit;



  delete from busi_public_netval;
  delete from busi_tz_netval;
  delete from busi_mgr_netval;

  --20140901ǰ��taȡ���ݣ�20140901���������faȡ����
  --insert into t_fund_value(id,fund_fjdm,fund_jzrq,fund_dwjz,fund_ljzz,fund_tbrq,isValid,fund_id,create_date) values (CMS_SEQ.nextVal,#fund_fjdm#,#fund_jzrq#,#fund_dwjz#,#fund_ljzz#,to_char(sysdate,'yyyymmdd'),1,#fund_id#,sysdate)

  --20140901ǰ��taȡ���ݣ�20140901���������faȡ����
  --insert into t_fund_value(id,fund_fjdm,fund_jzrq,fund_dwjz,fund_ljzz,fund_tbrq,isValid,fund_id,create_date) values (CMS_SEQ.nextVal,#fund_fjdm#,#fund_jzrq#,#fund_dwjz#,#fund_ljzz#,to_char(sysdate,'yyyymmdd'),1,#fund_id#,sysdate)

  insert into busi_public_netval (id,pt_id,product_no,product_name,unit_net_val,total_net_val,net_val_date,cp_id)
    select sync_task_seq.nextVal,b.fund_id,b.fund_code,b.fund_name,
       case when a.nav<1 then rpad('0'||a.nav,6,'0') when a.nav = 1 then rpad(a.nav||'.',6,'0')  else rpad(a.nav,6,'0') end ,
       case when a.accumulativenav<1 then rpad('0'||a.accumulativenav,6,'0') when a.accumulativenav = 1 then rpad(a.accumulativenav||'.',6,'0')  else rpad(a.accumulativenav,6,'0') end,
        to_date(a.tradedate,'yyyymmdd'),b.cp_id  from zsta.uv_xx_fundnav@ta_dblink a, t_fund_value_tmp b where a.nav is not null and a.fundcode = b.fund_code and a.tradedate = b.fund_tradedate and b.type = 1 and to_date(b.fund_tradedate,'yyyymmdd')<v_date;

  insert into busi_public_netval (id,pt_id,product_no,product_name,unit_net_val,total_net_val,net_val_date,cp_id)
    select sync_task_seq.nextVal, b.fund_id, b.fund_code, b.fund_name, a.nav ,a.accumulativenav, to_date(a.tradedate,'yyyymmdd'), b.cp_id   from v_fundnav@wbdb_link a, t_fund_value_tmp b where a.nav is not null and a.fundcode = b.fund_code and a.tradedate = b.fund_tradedate and b.type = 1 and to_date(b.fund_tradedate,'yyyymmdd')>=v_date;

  insert into busi_tz_netval (id,pt_id,product_no,product_name,unit_net_val,total_net_val,net_val_date,cp_id)
    select sync_task_seq.nextVal,b.fund_id,b.fund_code,b.fund_name,
         case when a.nav<1 then rpad('0'||a.nav,6,'0') when a.nav = 1 then rpad(a.nav||'.',6,'0')  else rpad(a.nav,6,'0') end ,
         case when a.accumulativenav<1 then rpad('0'||a.accumulativenav,6,'0') when a.accumulativenav = 1 then rpad(a.accumulativenav||'.',6,'0')  else rpad(a.accumulativenav,6,'0') end,
         to_date(a.tradedate,'yyyymmdd'),b.cp_id  from zsta.uv_xx_fundnav@ta_dblink a, t_fund_value_tmp b where a.nav is not null and a.fundcode = b.fund_code and a.tradedate = b.fund_tradedate and b.type = 2 and to_date(b.fund_tradedate,'yyyymmdd')<v_date;

  insert into busi_tz_netval (id,pt_id,product_no,product_name,unit_net_val,total_net_val,net_val_date,cp_id)
   select  sync_task_seq.nextVal, b.fund_id, b.fund_code, b.fund_name, a.nav ,a.accumulativenav, to_date(a.tradedate,'yyyymmdd'), b.cp_id  from v_fundnav@wbdb_link a, t_fund_value_tmp b where a.nav is not null and a.fundcode = b.fund_code and a.tradedate = b.fund_tradedate and b.type = 2 and to_date(b.fund_tradedate,'yyyymmdd')>=v_date;

   -- ����  �����˾�ֵͬ������
     insert into busi_mgr_netval (id,pt_id,product_no,product_name,unit_net_val,total_net_val,net_val_date,cp_id)
    select sync_task_seq.nextVal,b.fund_id,b.fund_code,b.fund_name,
         case when a.nav<1 then rpad('0'||a.nav,6,'0') when a.nav = 1 then rpad(a.nav||'.',6,'0')  else rpad(a.nav,6,'0') end ,
         case when a.accumulativenav<1 then rpad('0'||a.accumulativenav,6,'0') when a.accumulativenav = 1 then rpad(a.accumulativenav||'.',6,'0')  else rpad(a.accumulativenav,6,'0') end,
         to_date(a.tradedate,'yyyymmdd'),b.cp_id
         from zsta.uv_xx_fundnav@ta_dblink a, t_fund_value_tmp b where a.nav is not null and a.fundcode = b.fund_code and a.tradedate = b.fund_tradedate and b.type = 3 and to_date(b.fund_tradedate,'yyyymmdd')<v_date;

  insert into busi_mgr_netval (id,pt_id,product_no,product_name,unit_net_val,total_net_val,net_val_date,cp_id)
       select sync_task_seq.nextVal, b.fund_id, b.fund_code, b.fund_name, a.nav ,a.accumulativenav, to_date(a.tradedate,'yyyymmdd'), b.cp_id  from v_fundnav@wbdb_link a, t_fund_value_tmp b where a.nav is not null and a.fundcode = b.fund_code and a.tradedate = b.fund_tradedate and b.type = 3 and to_date(b.fund_tradedate,'yyyymmdd')>=v_date;

  --�ͷ�
  update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;



  v_msg :='ͬ���ɹ���';
  insert into t_fund_job_running_log(job_name,job_running_log) values('��ֵͬ����ʱ����',v_msg);
commit;
  exception
    when others then
      v_msg :='ͬ��ʧ�ܣ�ԭ��'|| sqlcode || ':' || sqlerrm;
      rollback;
      insert into t_fund_job_running_log(job_name,job_running_log) values('��ֵͬ����ʱ����',v_msg);
      update t_fund_job_status t set t.job_status = 0 where t.job_en_name = v_job_name;
      --commit;

end sync_old_fund_value;
/

