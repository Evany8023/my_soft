CREATE OR REPLACE PROCEDURE SMZJ.SYNC_QUARTERLY_BA_DATA
-- *************************************************************************
-- SYSTEM:       �е�ϵͳ
-- SUBSYS:       TA��ϵͳ
-- PROGRAM:      SYNC_ACCT_ALL_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  ͬ����Ӫƽ̨���ȱ�������
-- INPUT:
-- OUTPUT:
-- RETURN:       0    ��������
--               -1   ���ݿ����
  --֤ȯ
--   comment on column v_ysmzj_jdbasj_zq.VC_XMBH is '��Ŀ���';
--  --  comment on column v_ysmzj_jdbasj_zq.VC_CPDM is '��Ʒ����';
--  comment on column v_ysmzj_jdbasj_zq.VC_CPMC is '��Ʒ����';
--  comment on column v_ysmzj_jdbasj_zq.VC_BADM is '��������';
--  comment on column v_ysmzj_jdbasj_zq.L_YEAR is '�������';
--  comment on column v_ysmzj_jdbasj_zq.L_JD is '������(1:��һ����;2:�ڶ�����;3:��������;4:���ļ���)';
--  comment on column v_ysmzj_jdbasj_zq.L_BBLX is '��������(1-֤ȯ��,2-��Ȩ��)';
--  comment on column v_ysmzj_jdbasj_zq.EN_ZCZZGM is '��ĩ�����ʲ���ֵ';
--  --  comment on column v_ysmzj_jdbasj_zq.EN_JMJZGM is '��ĩ����ֵ��ģ';
--  comment on column v_ysmzj_jdbasj_zq.EN_XMFY is '��ط���';
--  comment on column v_ysmzj_jdbasj_zq.EN_GLF is '�����';
--  comment on column v_ysmzj_jdbasj_zq.EN_TGF is '�йܷ�';
--  comment on column v_ysmzj_jdbasj_zq.EN_YYFWF is '��Ӫ�����';
--  comment on column v_ysmzj_jdbasj_zq.EN_XGFY is '������ط���';
--  comment on column v_ysmzj_jdbasj_zq.en_jsggm is '�����깺��ģ';
--  comment on column v_ysmzj_jdbasj_zq.en_jshgm is '������ع�ģ%';
--  comment on column v_ysmzj_jdbasj_zq.en_ljsggm is '���������ۼ��깺��ģ';
--  comment on column v_ysmzj_jdbasj_zq.en_ljshgm is '���������ۼ���ع�ģ';
--  comment on column v_ysmzj_jdbasj_zq.en_jmjjfe is '��ĩ����ݶ�';
--  comment on column v_ysmzj_jdbasj_zq.en_jmdwjz is '��ĩ��λ��ֵ';
--  comment on column v_ysmzj_jdbasj_zq.en_jmljdwjz is '��ĩ�ۼƵ�λ��ֵ';
--  comment on column v_ysmzj_jdbasj_zq.en_jmjsy is '����ĩ������';
--  comment on column v_ysmzj_jdbasj_zq.en_jdfh is '���Ȼ���ֺ�';
--  comment on column v_ysmzj_jdbasj_zq.D_FBSJ is '����ʱ��';
--  comment on column v_ysmzj_jdbasj_zq.L_FBZT is '����״̬(0-ȡ��������1-�ѷ���)';
  /* ��Ȩ
  comment on column V_YSMZJ_JDBASJ_GQ.VC_XMBH is '��Ŀ���';
comment on column V_YSMZJ_JDBASJ_GQ.VC_CPDM is '��Ʒ����';
comment on column V_YSMZJ_JDBASJ_GQ.VC_CPMC is '��Ʒ����';
comment on column V_YSMZJ_JDBASJ_GQ.VC_BADM is '��������';
comment on column V_YSMZJ_JDBASJ_GQ.L_YEAR is '�������';
comment on column V_YSMZJ_JDBASJ_GQ.L_JD is '������(1:��һ����;2:�ڶ�����;3:��������;4:���ļ���)';
comment on column V_YSMZJ_JDBASJ_GQ.L_BBLX is '��������(1-֤ȯ��,2-��Ȩ��)';
comment on column V_YSMZJ_JDBASJ_GQ.EN_XMFY is '��ط���';
comment on column V_YSMZJ_JDBASJ_GQ.EN_GLF is '�����';
comment on column V_YSMZJ_JDBASJ_GQ.EN_TGF is '�йܷ�';
comment on column V_YSMZJ_JDBASJ_GQ.EN_YYFWF is '��Ӫ�����';
comment on column V_YSMZJ_JDBASJ_GQ.EN_XGFY is '������ط���';
comment on column V_YSMZJ_JDBASJ_GQ.EN_TCZCGM is 'Ͷ���ʲ���ģ';
comment on column V_YSMZJ_JDBASJ_GQ.EN_TCGMZB is '��Ͷ����ģռʵ�ɱ���%';
comment on column V_YSMZJ_JDBASJ_GQ.EN_JCZCJZ is '�����ʲ���ģ';
comment on column V_YSMZJ_JDBASJ_GQ.EN_JMJZGM is '��ĩ�����ʲ���ֵ';
comment on column V_YSMZJ_JDBASJ_GQ.EN_ZCZZGM is '��ĩ�����ʲ���ֵ';
comment on column V_YSMZJ_JDBASJ_GQ.EN_JMJSY is '���Ȼ�������';
comment on column V_YSMZJ_JDBASJ_GQ.EN_JDFH is '���Ȼ���ֺ�';
comment on column V_YSMZJ_JDBASJ_GQ.D_FBSJ is '����ʱ��';
comment on column V_YSMZJ_JDBASJ_GQ.L_FBZT is '����״̬(0-ȡ��������1-�ѷ���)';
*/

-- AUTHOR:       pangzuoqing
-- CREATE DATE:  2016-03-21
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
is
   v_zq_date timestamp;
   v_gq_date timestamp;
   -- ֤ȯ��
   V_XMBH  varchar2(50 char); 
   V_BADM varchar2(50 char); 
   V_CPDM  varchar2(50 char); 
   V_CPMC  varchar2(200 char); 
   V_YEAR  varchar2(50 char); 
   V_JD  varchar2(50 char); 
   V_BBLX  varchar2(50 char); 
   V_ZCZZGM  varchar2(50 char); 
   V_JMJZGM  varchar2(50 char); 
   V_XMFY  varchar2(50 char); 
   V_GLF   varchar2(50 char); 
   V_TGF  varchar2(50 char); 
   V_YYFWF  varchar2(50 char); 
   V_XGFY  varchar2(50 char); 
   V_JSGGM   varchar2(50 char); 
   V_JSHGM  varchar2(50 char); 
   V_LJSGGM    varchar2(50 char); 
   V_LJSHGM    varchar2(50 char); 
   V_JMJJFE    varchar2(50 char); 
   V_JMDWJZ    varchar2(50 char); 
   V_JMLJDWJZ    varchar2(50 char); 
   V_JMJSY  varchar2(50 char); 
   V_JDFH    varchar2(50 char); 
   V_FBSJ  timestamp; 
   V_FBZT varchar2(50 char); 

   -- ��Ȩ��
  V_TCZCGM    varchar2(50 char); 
  V_TCGMZB    varchar2(50 char); 
  V_JCZCJZ    varchar2(50 char); 
  V_COUNT integer;
    v_msg                        varchar2(1000);
    v_job_name                   varchar2(100):= 'sync_quarterly_ba_data';

cursor zq_cursor is 
select VC_XMBH,VC_CPDM,VC_CPMC,VC_BADM,L_YEAR,L_JD,L_BBLX,trim(to_char(EN_ZCZZGM,'9999999999990.9999')),trim(to_char(EN_JMJZGM,'9999999999990.9999')),
trim(to_char(EN_XMFY,'9999999999990.9999')),trim(to_char(EN_GLF,'9999999999990.9999')),
trim(to_char(EN_TGF,'9999999999990.9999')),trim(to_char(EN_YYFWF,'9999999999990.9999')),
trim(to_char(EN_XGFY,'9999999999990.9999')),trim(to_char(EN_JSGGM,'9999999999990.9999'))
,trim(to_char(EN_JSHGM,'9999999999990.9999')),trim(to_char(EN_LJSGGM,'9999999999990.9999')),
trim(to_char(EN_LJSHGM,'9999999999990.9999')),trim(to_char(EN_JMJJFE,'9999999999990.9999')),
trim(to_char(EN_JMDWJZ,'9999999999990.9999')),trim(to_char(EN_JMLJDWJZ,'9999999999990.9999')),
trim(to_char(EN_JMJSY,'9999999999990.9999')),EN_JDFH,D_FBSJ,L_FBZT
 from tgyyzx.v_YSMZJ_JDBASJ_zq@Yy_Dblimk where   D_FBSJ > v_zq_date ;
 
 
cursor gq_cursor is 
select VC_XMBH,VC_CPDM,VC_CPMC,VC_BADM,L_YEAR,L_JD,L_BBLX, trim(to_char(EN_XMFY,'9999999999990.9999')),
 trim(to_char(EN_GLF,'9999999999990.9999')) , trim(to_char(EN_TGF,'9999999999990.9999')),
  trim(to_char(EN_YYFWF,'9999999999990.9999')), trim(to_char(EN_XGFY,'9999999999990.9999')),
   trim(to_char(EN_TCZCGM,'9999999999990.9999')), trim(to_char(EN_TCGMZB,'9999999999990.9999'))
, trim(to_char(EN_JCZCJZ,'9999999999990.9999')), trim(to_char(EN_JMJZGM,'9999999999990.9999')), 
trim(to_char(EN_ZCZZGM,'9999999999990.9999')), trim(to_char(EN_JMJSY,'9999999999990.9999')), trim(to_char(EN_JDFH,'9999999999990.9999'))
 ,D_FBSJ,L_FBZT
 from tgyyzx.v_YSMZJ_JDBASJ_gQ@Yy_Dblimk where  D_FBSJ > v_gq_date ;


begin   
  
select max(d.updatetime) into v_zq_date from busi_quarterly_data d ;
if v_zq_date is null then
  select to_date('20120101','yyyymmdd') into v_zq_date from dual;
end if;

select max(d.updatetime) into v_gq_date from busi_quarterly_gu_data d ;
if v_gq_date is null then
  select to_date('20120101','yyyymmdd') into v_gq_date from dual;
end if;

open zq_cursor;
loop
    fetch zq_cursor into V_XMBH,V_CPDM,V_CPMC,V_BADM,V_YEAR,V_JD,V_BBLX,V_ZCZZGM,V_JMJZGM,V_XMFY,V_GLF,V_TGF,V_YYFWF,V_XGFY,V_JSGGM,V_JSHGM,V_LJSGGM,
                         V_LJSHGM,V_JMJJFE,V_JMDWJZ,V_JMLJDWJZ,V_JMJSY,V_JDFH,V_FBSJ,V_FBZT;
    if zq_cursor%notfound then
       exit;
    end if;
    select count(1) into V_COUNT from busi_quarterly_data d where d.year=V_YEAR and d.quarterly=V_JD and d.pt_no=V_CPDM;
    
    if  V_FBZT  ='0' and v_COUNT > 0 then 
       delete from busi_quarterly_data d where d.year=V_YEAR and d.quarterly=V_JD and d.pt_no=V_CPDM;
    elsif V_FBZT='1' and v_COUNT> 0 then
      update busi_quarterly_data d set d.xmbh=V_XMBH,d.pt_no=V_CPDM,d.marketcode=V_BADM,d.year=V_YEAR,d.quarterly=V_JD,
      d.ZCZZGM=V_ZCZZGM,d.JMZZGM=V_JMJZGM,d.xgfy=V_XMFY,d.glf=V_GLF,d.tgf=V_TGF,d.YYFWF=V_YYFWF,d.QTXGF=V_XGFY,d.BJSGGM=V_JSGGM,
      d.bjshgm=V_JSHGM,d.LJSGGM=V_LJSGGM,d.LJSHGM=V_LJSHGM,d.JMJJFE=V_JMJJFE,d.jmdwjz=V_JMDWJZ,d.JMJJSY=V_JMJSY,d.jmjjfh=V_JDFH,d.JMLJJZ=V_JMLJDWJZ
      ,d.UPDATETIME=V_FBSJ,d.is_publish=V_FBZT
       where d.year=V_YEAR and d.quarterly=V_JD and d.pt_no=V_CPDM;
      
     elsif   V_FBZT='1' and v_COUNT <1 then
       insert into   busi_quarterly_data(id,xmbh,pt_no,marketcode,year,quarterly,ZCZZGM,JMZZGM,xgfy,glf,tgf,YYFWF,QTXGF,BJSGGM,bjshgm,LJSGGM,LJSHGM,JMJJFE,jmdwjz,JMJJSY,jmjjfh,JMLJJZ,UPDATETIME,is_publish) 
       values(id_seq.nextval,V_XMBH,V_CPDM,V_BADM,V_YEAR,V_JD,V_ZCZZGM,V_JMJZGM,V_XMFY,V_GLF,V_TGF,V_YYFWF,V_XGFY,V_JSGGM,V_JSHGM,V_LJSGGM,V_LJSHGM,V_JMJJFE,V_JMDWJZ,V_JMJSY,V_JDFH,V_JMLJDWJZ ,V_FBSJ,V_FBZT);
     end if;
          
end  loop;
close zq_cursor;

open gq_cursor;
loop
fetch gq_cursor into V_XMBH,V_CPDM,V_CPMC,V_BADM,V_YEAR,V_JD,V_BBLX,V_XMFY,V_GLF,V_TGF,V_YYFWF,V_XGFY,V_TCZCGM,
                     V_TCGMZB,V_JCZCJZ,V_JMJZGM,V_ZCZZGM,V_JMJSY,V_JDFH,V_FBSJ,V_FBZT;
    if gq_cursor%notfound then
       exit;
    end if;
   select count(1) into V_COUNT from busi_quarterly_gu_data d where d.year=V_YEAR and d.quarterly=V_JD  and d.pt_no=V_CPDM;
    if  V_FBZT  ='0' and v_COUNT > 0 then 
       delete from busi_quarterly_gu_data d where d.year=V_YEAR and d.quarterly=V_JD and d.pt_no=V_CPDM;
    elsif V_FBZT='1' and v_COUNT> 0 then
    
      update busi_quarterly_gu_data d set d.xmbh=V_XMBH,d.pt_no=V_CPDM,d.marketcode=V_BADM,d.year=V_YEAR,d.quarterly=V_JD,
      d.xgfy=V_XMFY,d.glf=V_GLF,d.tgf=V_TGF,d.yyfwf=V_YYFWF,d.qtxgf=V_XGFY,d.YTCGM=V_TCZCGM,
      d.YTCGMBL=V_TCGMZB,d.LJSGGM=V_JCZCJZ,d.JCJJZCJZ=V_JMJZGM,d.JMJJZCJZ=V_ZCZZGM,d.JDJJLR=V_JMJSY,d.JMJJFH=V_JDFH
      ,d.UPDATETIME=V_FBSJ,d.is_publish=V_FBZT
       where d.year=V_YEAR and d.quarterly=V_JD and d.pt_no=V_CPDM; 
      
     elsif   V_FBZT='1' and v_COUNT <1 then
     
       insert into   busi_quarterly_gu_data(id,xmbh,pt_no,marketcode,year,quarterly,xgfy,glf,tgf,yyfwf,qtxgf,YTCGM,YTCGMBL,LJSGGM,JCJJZCJZ,JMJJZCJZ,JDJJLR,JMJJFH,UPDATETIME,is_publish) 
       values(id_seq.nextval,V_XMBH,V_CPDM,V_BADM,V_YEAR,V_JD,V_XMFY,V_GLF,V_TGF,V_YYFWF,V_XGFY,V_TCZCGM,V_TCGMZB,V_JCZCJZ,V_JMJZGM,V_ZCZZGM,V_JMJSY,V_JDFH,V_FBSJ,V_FBZT);
      
     end if;
          
end  loop;
close gq_cursor;

update busi_quarterly_gu_data d set (d.pt_id,d.pt_name,d.cp_id,d.cp_name,d.cp_no)=
(select p.id,p.name,c.id,c.cp_name,c.insti_code  from busi_product p join busi_company c on c.id=p.cp_id where p.product_no=d.pt_no)

where exists(select p.id   from busi_product p join busi_company c on c.id=p.cp_id where p.product_no=d.pt_no
);

update busi_quarterly_data d set (d.pt_id,d.pt_name,d.cp_id,d.cp_name,d.cp_no)=
(select p.id,p.name,c.id,c.cp_name,c.insti_code  from busi_product p join busi_company c on c.id=p.cp_id where p.product_no=d.pt_no)

where exists(select p.id   from busi_product p join busi_company c on c.id=p.cp_id where p.product_no=d.pt_no
);

commit;

EXCEPTION
    when others then

        rollback;

        v_msg :='ͬ��ʧ�ܣ�ԭ��' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_QUARTERLY_BA_DATA;
/

