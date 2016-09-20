CREATE OR REPLACE FUNCTION SMZJ.getPreWorkDayByAdvance(sqrq in varchar2,advance varchar2 )
 RETURN VARCHAR2
 IS
  predaywork varchar2(16);
 BEGIN
  select rq into predaywork from ( select rank() over(order by t.rq desc) as NUMS ,t.rq from  zsta.rlb@ta_dblink  t where t.rq <sqrq and t.gzr='1' ) where NUMS=advance ;
  RETURN predaywork;
 END;
/

