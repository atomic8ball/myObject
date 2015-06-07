delimiter ;;
drop procedure if exists writekey;;
create procedure writekey(in _key longtext, type nvarchar(9), number float, string longtext)
begin
	set tx_isolation='REPEATABLE-READ';
	set @key := _key, @parent := 1, @id = 0, @type = type, @number = number, @string = string;

	while length(@key) > 0 do
		set @part := substring(@key, 1, instr(@key, '.'));
		set @key = replace(@key, @part, '');
        set @part := replace(@part, '.', '');
        if length(@part) = 0 then
			set @part = @key;
            set @key = '';
        end if;
        set @id := 0;
        while @id = 0 do 
			select id into @id
			from okeys 
			where ifnull(parent, -1) = ifnull(@parent, -1)
				and csname = crc32(@part) 
				and name = @part;
			if @id = 0 then
				insert ignore okeys(parent, name, csname, type, number, string)
				values (@parent, @part, crc32(@part), 'object', null, null);
				set @id := last_insert_id();
			end if;
		end while;
        set @parent := @id;
	end while;
    
    delete from okeys
    where parent = @id;

	update okeys
    set type = @type, number = @number, string = @string
    where id = @id;
end
;;


delimiter ;
call writekey('foo.bar', 'string', null, 'bob');
call readkey('foo');

