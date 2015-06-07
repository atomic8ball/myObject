delimiter ;;
drop procedure if exists search;;
create procedure search(in _key nvarchar(255), in _string longtext, in _number float) begin
	drop table if exists res;
	create temporary table res (parent bigint unsigned, name nvarchar(1024) not null) engine=memory;

	set sql_safe_updates := 0;

	insert res
	select parent, name
	from okeys
	where csname = crc32(_key)
		and name = _key
		and (
			string = _string 
            or number = _number
		);

	while row_count() > 0 do
		update res r
		inner join okeys o
			on o.id = r.parent
		set r.name = concat(o.name,'.', r.name), r.parent = o.parent
		where r.parent != 1;
	end while;

	set sql_safe_updates := 1;
		
	select name
	from res;

	drop table if exists res;
end;;
delimiter ;

call search('name', 'Dennis', null);
call search('age', null, 37);