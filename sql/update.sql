alter table cramuser rename column userrid to userid;
alter table activityuser rename column userrid to userid;
alter table manager rename column userrid to userid;
alter table projectuser rename column userrid to userid;
alter table task rename column userrid to userid;
alter table teamleader rename column userrid to userid;
alter table teamuser rename column userrid to userid;
alter table userversion rename column userrid to userid;
alter table cramuser add column email varchar;
alter table cramuser add column name varchar(20);
alter table cramuser add column lastname varchar(20);
create or replace function createuserversion() returns trigger
    language plpgsql
as
$$
begin
    insert into userversion values(new.userid, 0) ;
    return null;
end;
$$;
-- userpwd not null
alter table cramuser alter column userpwd drop not null;
--todo supprimer la colonne userpw
