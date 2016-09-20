create or replace view smzj.v_busi_fund_values_order as
select "ID","FUNDCODE","TRADEDAY","NAV","ACCUMULATIVENAV","WFSY","QRLJSY","FUNDNAME","FUNDID","COMID","CREATE_DATE" from busi_all_fund_vaues v
    order by v.tradeday desc;

