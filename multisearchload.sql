delimiter ;;
drop procedure if exists multisearchload;;
create procedure multisearchload(in _keys longtext, in _string longtext, in _number float) begin
	drop table if exists searchkeys;
	create temporary table searchkeys(_key longtext not null) engine = memory;
	drop table if exists searchres;
	create temporary table searchres(parent bigint unsigned, name nvarchar(1024) not null) engine = memory;
	

	
	set @keys := _keys;
	while length(@keys > 0) do
		set @key := substring(@keys, 1, instr(@keys, '|'));
		set @keys = replace(@keys, @key, '');
		set @key := replace(@key, '|', '');
		insert searchkeys
		set _key=@key;
		
	end while;
	insert searchkeys
	
set sql_safe_updates := 0;
end;;
delimiter ;
