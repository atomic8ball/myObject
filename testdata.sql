set @parent = 1, @name = 'foo', @type = 'object', @number = null, @string = null;
insert okeys (parent, name, csname, type, number, string)
values (@parent, @name, crc32(@name), @type, @number, @string);

set @parent = last_insert_id(), @name = 'bar', @type = 'object', @number = null, @string = null;
insert okeys (parent, name, csname, type, number, string)
values (@parent, @name, crc32(@name), @type, @number, @string);

set @parent = last_insert_id(), @name = 'baz', @type = 'object', @number = null, @string = null;
insert okeys (parent, name, csname, type, number, string)
values (@parent, @name, crc32(@name), @type, @number, @string);

set @parent = last_insert_id(), @name = 'qux', @type = 'string', @number = null, @string = 'I am qux!';
insert okeys (parent, name, csname, type, number, string)
values (@parent, @name, crc32(@name), @type, @number, @string);

select *
from okeys;


    
    
