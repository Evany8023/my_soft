CREATE OR REPLACE FUNCTION SMZJ.getNextWorkDay(sqrq in varchar2,delay varchar2 )
 RETURN VARCHAR2
 IS
  predaywork varchar2(16);
 BEGIN
  select rq into predaywork from ( select rank() over(order by t.rq asc) as NUMS ,t.rq from  zsta.rlb@ta_dblink  t where t.rq >sqrq and t.gzr='1' ) where NUMS=delay ;
  RETURN predaywork;
 END;
/

