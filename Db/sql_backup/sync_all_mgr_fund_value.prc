CREATE OR REPLACE PROCEDURE SMZJ.sync_all_mgr_fund_value  is

  v_msg   varchar2(4000);
  v_year      varchar2(4) := '2014';
  v_date      date;
  v_create_date varchar2(16);
  v_fund_id   varchar2(32 char );
  v_fund_name   varchar2(100 char );
  v_com_id   varchar2(32 char );
  v_fund_clr  varchar2(32);
  v_fund_code varchar2(16);


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
  v_is_mocode_kfr_pl varchar(10 char );
  --������Ϣ
  cursor fundinfo_cur is
    select t.id, to_char(t.publish_date,'yyyyMMdd') as fund_clrq, t.product_no,t.public_net_period , t.invest_net_period,  t.mgr_net_period,t.is_close_master_net ,t.cp_id,t.name
      from busi_product t
     where t.is_validate=1
       and t.is_examine=1 ;
begin

  select to_date('20140901','yyyymmdd') into v_date from dual;
  select to_char(sysdate,'yyyymmdd') into v_create_date from dual;

  execute immediate 'truncate table BUSI_ALL_MGR_FUND_VALUE';


  open fundinfo_cur;
  loop
    fetch fundinfo_cur
      into v_fund_id,v_fund_clr, v_fund_code, v_fund_jztbzq, v_fund_tzzjztbzq,v_fund_glrjztbzq,v_is_mocode_kfr_pl,v_com_id,v_fund_name;

    if fundinfo_cur%notfound then
      exit;
    end if;

    -- ������ ���� ͬ��
    if v_fund_glrjztbzq = 1 then
            insert into BUSI_ALL_MGR_FUND_VALUE(fund_code,fund_tradedate,fund_id)
            select v_fund_code,rq,v_fund_id from (select v_fund_clr as rq from dual);
    end if;
  ----ͬ�������ա������ھ�ֵ��
    if v_fund_glrjztbzq = 2 then
          insert into BUSI_ALL_MGR_FUND_VALUE(fund_code,fund_tradedate,fund_id)   select v_fund_code,rq,v_fund_id from (
            select v_fund_clr as rq from dual
            union
            --ÿ�����һ��������
            select max(rq) as rq from zsta.rlb@ta_dblink where substr(rq, 1, 4) >= v_year and gzr = '1' and rq <= v_create_date group by substr(rq, 1, 6));

    end if;
   --ͬ�������ա������ڡ�ÿ�����һ�������գ�
    if v_fund_glrjztbzq = 3 then
          insert into BUSI_ALL_MGR_FUND_VALUE(fund_code,fund_tradedate,fund_id)
                select v_fund_code,rq,v_fund_id from (
                select v_fund_clr as rq from dual union
                --������
                --ÿ�����һ��������
                select max(rq)as rq from zsta.rlb@ta_dblink t where substr(rq, 1, 4) >= v_year and gzr = '1' and t.rq <= v_create_date group by  NEXT_DAY(to_date(rq, 'yyyymmdd'),'����һ')
                );
    end if;
    ---ͬ��ÿһ��������;
    if v_fund_glrjztbzq = 4 then

      insert into BUSI_ALL_MGR_FUND_VALUE(fund_code,fund_tradedate,fund_id)
        select v_fund_code,rq,v_fund_id from (select rq  from zsta.rlb@ta_dblink where gzr='1' and rq <= v_create_date  and substr(rq, 1, 4) >= v_year);

    end if;
   --ÿ�������һ��������
    if v_fund_glrjztbzq = 5 then
               insert into BUSI_ALL_MGR_FUND_VALUE(fund_code,fund_tradedate,fund_id)
                select v_fund_code,rq,v_fund_id  from (
                select v_fund_clr as rq from dual
                union
                select max(rq) as rq from zsta.rlb@ta_dblink where substr(rq, 1, 4) >= v_year and gzr = '1' and rq <= v_create_date and substr(rq,5,2) in ('03','06','09','12') group by substr(rq, 1, 6)
             );

   end if;

    insert into BUSI_ALL_MGR_FUND_VALUE(fund_code,fund_tradedate,fund_id)
     select v_fund_code,rq,v_fund_id from(
     select rq from zsta.uv_xx_fundstatus@ta_dblink t where t.jjdm = v_fund_code and t.jjzt in ('0', '5', '6') and t.gzr = '1' and t.rq <= v_create_date
     );

  end loop;
  close fundinfo_cur;

  v_msg :='ͬ���ɹ���';
  insert into t_fund_job_running_log(job_name,job_running_log) values('sync_all_mgr_fund_value ��ֵ������ȫ�����ڣ����Ӷ��˵� ͬ����ʱ����',v_msg);
commit;
exception
    when others then
      v_msg :='ͬ��ʧ�ܣ�ԭ��'|| sqlcode || ':' || sqlerrm;
      insert into t_fund_job_running_log(job_name,job_running_log) values(' sync_all_mgr_fund_value ��ֵ������ȫ�����ڣ����Ӷ��˵� ͬ����ʱ����',v_msg);
      commit;

end sync_all_mgr_fund_value;
/

