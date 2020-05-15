-- Traffic pattern from a file

package.path = package.path ..";?.lua;test/?.lua;app/?.lua;../?.lua"

require "Pktgen";

-- Specify variable to make it downlink or uplink
link = "downlink";
time_step = 5;		-- seconds

sendport = 0;
total_time = 0;
pkt_size = 64;

-- Take two lists and create one table with a merged value of the tables.
-- Return a set or table = { { timo, pps }, ... }
function Set(step, list)
	local	set = { };		-- Must have a empty set first.

	for i,v in ipairs(list) do
		set[i] = { timo = step, pps = v };
	end

	return set;
end

-- see if the file exists
function file_exists(file)
	local f = io.open(file, "rb");
	if f then f:close() end
	return f ~= nil;
end

-- get specific lines from a file, returns an empty
-- list/table if the file does not exist
function lines_from(file)
	if not file_exists(file) then return {} end
	local lines = {};
	local count = 0;
	for line in io.lines(file) do
		count = count + 1;
		if count == 4 then
			local splitted = stringsplit(line, "%s");
			pkt_size = tonumber(splitted[5]);
		end
		if count > 5 and count < 294 then
			lines[#lines + 1] = tonumber(line) * 0.43;
		end
	end
	return lines
end

function stringsplit (inputstr, sep)
	if sep == nil then
		sep = "%s";
	end
	local t = {};
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str);
	end
	return t
end

function main()
	local sending = 0;

	local file = '/opt/il_trafficgen/pktgen/scripts/'..link..'.txt';
	local lines = lines_from(file);
	--for k,v in pairs(lines) do
	--	print('line[' .. k .. ']', v);
	--end

	local trlst = Set(time_step, lines);


	-- Stop the port sending and reset to
	pktgen.stop(sendport);
	sleep(2);					-- Wait for stop to happen (not really needed)
	pktgen.set(sendport, "size", pkt_size);
	pktgen.range.pkt_size("0", "start", pkt_size);
	pktgen.range.pkt_size("0", "min", pkt_size);
	pktgen.range.pkt_size("0", "max", pkt_size);
	sleep(1);

	total_time = 0;
	loop = 0;
	-- set this with the index of traffic to start the first time, -1 if you want to start from beginning
	offset = -1;
	while true do
		loop = loop + 1;
		-- v is the table to values created by the Set(x,y) function
		for idx,v in pairs(trlst) do
			if loop == 1 then
				if idx < offset then
					goto continue
				end
			end
			--printf("   PPS %d for %d seconds\n", v.pps, v.timo);

			-- Set the pps to the new value
			pktgen.set(sendport, "pps", v.pps);

			-- If not sending packets start sending them
			if ( sending == 0 ) then
				pktgen.start(sendport);
				sending = 1;
			end

			-- write pps in file
			file = io.open("/opt/il_trafficgen/pktgen/scripts/tmp-"..link..".txt", "w");
			file:write("timestamp: ", os.time(), '\n', "pps: ", v.pps, '\n');
			--os.time(os.date("!*t"))
			file:close();
			os.rename("/opt/il_trafficgen/pktgen/scripts/tmp-"..link..".txt", "/opt/il_trafficgen/pktgen/scripts/pps-"..link..".txt");

			-- Sleep until we need to move to the next pps value and timeout
			sleep(v.timo);
			total_time = total_time + v.timo;

			::continue::
		end
	end

	-- Stop the port and do some cleanup
	pktgen.stop(sendport);
	sending = 0;
end

printf("\n**** Traffic Profile***\n");
main();
printf("\n*** Traffic Profile Done (Total Time %d) ***\n", total_time);
