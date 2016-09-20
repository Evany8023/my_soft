CREATE OR REPLACE PROCEDURE SMZJ.SYNC_QUARTERLY_BA_DATA
-- *************************************************************************
-- SYSTEM:       中登系统
-- SUBSYS:       TA子系统
-- PROGRAM:      SYNC_ACCT_ALL_INFO
-- RELATED TAB:
-- SUBPROG:
-- REFERENCE:
-- DESCRIPTION:  同步运营平台季度备案数据
-- INPUT:
-- OUTPUT:
-- RETURN:       0    正常返回
--               -1   数据库错误
  --证券
--   comment on column v_ysmzj_jdbasj_zq.VC_XMBH is '项目编号';
--  --  comment on column v_ysmzj_jdbasj_zq.VC_CPDM is '产品代码';
--  comment on column v_ysmzj_jdbasj_zq.VC_CPMC is '产品名称';
--  comment on column v_ysmzj_jdbasj_zq.VC_BADM is '备案代码';
--  comment on column v_ysmzj_jdbasj_zq.L_YEAR is '报表年份';
--  comment on column v_ysmzj_jdbasj_zq.L_JD is '报表季度(1:第一季度;2:第二季度;3:第三季度;4:第四季度)';
--  comment on column v_ysmzj_jdbasj_zq.L_BBLX is '报表类型(1-证券类,2-股权类)';
--  comment on column v_ysmzj_jdbasj_zq.EN_ZCZZGM is '季末基金资产总值';
--  --  comment on column v_ysmzj_jdbasj_zq.EN_JMJZGM is '季末基金净值规模';
--  comment on column v_ysmzj_jdbasj_zq.EN_XMFY is '相关费用';
--  comment on column v_ysmzj_jdbasj_zq.EN_GLF is '管理费';
--  comment on column v_ysmzj_jdbasj_zq.EN_TGF is '托管费';
--  comment on column v_ysmzj_jdbasj_zq.EN_YYFWF is '运营服务费';
--  comment on column v_ysmzj_jdbasj_zq.EN_XGFY is '其他相关费用';
--  comment on column v_ysmzj_jdbasj_zq.en_jsggm is '本季申购规模';
--  comment on column v_ysmzj_jdbasj_zq.en_jshgm is '本季赎回规模%';
--  comment on column v_ysmzj_jdbasj_zq.en_ljsggm is '成立日起累计申购规模';
--  comment on column v_ysmzj_jdbasj_zq.en_ljshgm is '成立日起累计赎回规模';
--  comment on column v_ysmzj_jdbasj_zq.en_jmjjfe is '季末基金份额';
--  comment on column v_ysmzj_jdbasj_zq.en_jmdwjz is '季末单位净值';
--  comment on column v_ysmzj_jdbasj_zq.en_jmljdwjz is '季末累计单位净值';
--  comment on column v_ysmzj_jdbasj_zq.en_jmjsy is '基金季末净收益';
--  comment on column v_ysmzj_jdbasj_zq.en_jdfh is '季度基金分红';
--  comment on column v_ysmzj_jdbasj_zq.D_FBSJ is '更新时间';
--  comment on column v_ysmzj_jdbasj_zq.L_FBZT is '发布状态(0-取消发布，1-已发布)';
  /* 股权
  comment on column V_YSMZJ_JDBASJ_GQ.VC_XMBH is '项目编号';
comment on column V_YSMZJ_JDBASJ_GQ.VC_CPDM is '产品代码';
comment on column V_YSMZJ_JDBASJ_GQ.VC_CPMC is '产品名称';
comment on column V_YSMZJ_JDBASJ_GQ.VC_BADM is '备案代码';
comment on column V_YSMZJ_JDBASJ_GQ.L_YEAR is '报表年份';
comment on column V_YSMZJ_JDBASJ_GQ.L_JD is '报表季度(1:第一季度;2:第二季度;3:第三季度;4:第四季度)';
comment on column V_YSMZJ_JDBASJ_GQ.L_BBLX is '报表类型(1-证券类,2-股权类)';
comment on column V_YSMZJ_JDBASJ_GQ.EN_XMFY is '相关费用';
comment on column V_YSMZJ_JDBASJ_GQ.EN_GLF is '管理费';
comment on column V_YSMZJ_JDBASJ_GQ.EN_TGF is '托管费';
comment on column V_YSMZJ_JDBASJ_GQ.EN_YYFWF is '运营服务费';
comment on column V_YSMZJ_JDBASJ_GQ.EN_XGFY is '其他相关费用';
comment on column V_YSMZJ_JDBASJ_GQ.EN_TCZCGM is '投出资产规模';
comment on column V_YSMZJ_JDBASJ_GQ.EN_TCGMZB is '已投出规模占实缴比例%';
comment on column V_YSMZJ_JDBASJ_GQ.EN_JCZCJZ is '季初资产规模';
comment on column V_YSMZJ_JDBASJ_GQ.EN_JMJZGM is '季末基金资产净值';
comment on column V_YSMZJ_JDBASJ_GQ.EN_ZCZZGM is '季末基金资产总值';
comment on column V_YSMZJ_JDBASJ_GQ.EN_JMJSY is '季度基金收益';
comment on column V_YSMZJ_JDBASJ_GQ.EN_JDFH is '季度基金分红';
comment on column V_YSMZJ_JDBASJ_GQ.D_FBSJ is '更新时间';
comment on column V_YSMZJ_JDBASJ_GQ.L_FBZT is '发布状态(0-取消发布，1-已发布)';
*/

-- AUTHOR:       pangzuoqing
-- CREATE DATE:  2016-03-21
-- VERSION:
-- EDIT HISTORY:
-- *************************************************************************
is
   v_zq_date timestamp;
   v_gq_date timestamp;
   -- 证券类
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

   -- 股权类
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

        v_msg :='同步失败，原因：' || sqlcode || ':' || sqlerrm || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,500);
        insert into t_fund_job_running_log(job_name,job_running_log) values(v_job_name,v_msg);
        commit;
end SYNC_QUARTERLY_BA_DATA;
/

