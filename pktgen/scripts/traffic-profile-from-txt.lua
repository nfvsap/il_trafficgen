-- Traffic pattern from a file
-- Specify the file n main() to make it downlink or uplink

package.path = package.path ..";?.lua;test/?.lua;app/?.lua;../?.lua"

require "Pktgen";

local time_step = 5;		-- seconds

sendport = 0;
total_time = 0;

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

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
	if not file_exists(file) then return {} end
	lines = {};
	count = 0;
	for line in io.lines(file) do
		count = count + 1;
		if count > 5 and count < 294 then 
			lines[#lines + 1] = line;
		end
	end
	return lines
end

function main()
	local sending = 0;

	local file = '/opt/il_trafficgen/pktgen/scripts/downlink.txt';
	local lines = lines_from(file);
	for k,v in pairs(lines) do
		print('line[' .. k .. ']', v);
	end

	local trlst = Set(time_step, lines);

	-- Stop the port sending and reset to
	--pktgen.stop(sendport);
	--sleep(2);					-- Wait for stop to happen (not really needed)
	-- You should configure the ports, macs, ips.. etc with another script before running this script
	total_time = 0;
	-- v is the table to values created by the Set(x,y) function
	for _,v in pairs(trlst) do
		printf("   PPS %d for %d seconds\n", v.pps, v.timo);

		-- Set the pps to the new value
		pktgen.set(sendport, "pps", v.pps);

		-- If not sending packets start sending them
		if ( sending == 0 ) then
			pktgen.start(sendport);
			sending = 1;
		end

		-- Sleep until we need to move to the next pps value and timeout
		sleep(v.timo);
		total_time = total_time + v.timo;

	end

	-- Stop the port and do some cleanup
	pktgen.stop(sendport);
	sending = 0;
end

printf("\n**** Traffic Profile***\n");
main();
printf("\n*** Traffic Profile Done (Total Time %d) ***\n", total_time);
