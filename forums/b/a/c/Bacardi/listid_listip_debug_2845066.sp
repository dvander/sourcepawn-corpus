/*
	28.06.2026 - *update, "ban count" | replace getting address using engine.dll+offset to -> read address from location sign "banid callback" + offset to get ban count
	27.06.2026
	Source Dedicated Server Ban debug view tool
	- Bacardi

	For now, this plugin version works on SourceMod 1.12 and 32bit SRCDS.exe (Windows)
	- What you like also use for debug memory, program tool such like "CheatEngine - i386", so that you can navigate with given addresses.
	Use launch parameter -insecure "just in case" in srcds.exe and in your own game.

	Or if you have not smallest idea about tinkering memory and do not want VAC-ban to your Steam account, stop here and delete this file and plugin. Forget.

	And use this plugin only on your local PC + test server, not on public community server where are people playing.
*/

char AccountTypeChar[][] = {
	"I" /*Invalid*/,			"U" /*Single user*/,			"M" /*multiseat*/,
	"G" /*Game Server*/,		"A" /*anonymous game server*/,	"P" /*pending*/,
	"C" /*content server*/,		"g" /*group/clan*/,				"T" /*three IDTypes of chat accounts 'T' = flag Anon (0x80), 'c' = flag Clan (0x88), 'L' = flag Lobby (0x84)*/,
	"i" /*P2P, console user*/,	"a"  /*Anon user*/,
	//rest numbers are invalid 'i'
}

//steamid instance detail
#define INSTANCE_ALL			0
#define INSTANCE_DESKTOP		(1<<0)
#define INSTANCE_CONSOLE		(1<<1)
#define INSTANCE_WEB			(1<<2)

//for array variable int64steam
#define LOW32BITS 0
#define HIGH32BITS 1

enum struct SteamID
{
	int id;		//32bit (0x00 0x00 0x00 0x00) steam account number (Low32bits)

	//(High32bits)
	int instance;	//20bit (0x00 0x00 0x0)
	int type;	//4bit	(0x0)	steam account type
	int universe;	//8bit	(0x00)	Universe invalid = 0, universe public = 1, universe beta = 2, universe internal = 3, universe dev = 4

	int data;	//32bit storage, it is same data as three variables above (High32bits)

	char steamid3[64]; //creates render() output here
	char steamid2[64];
	char steam64[64];
	int int64steam[2];

	void extractdata() //remember execute this after obtain data
	{
		this.instance	=  this.data & 0x000FFFFF;
		this.type		= (this.data & 0x00F00000) >> 20;
		this.universe	= (this.data & 0xFF000000) >> 24;
	}

	void render() //remember execute this to get steamid strings (I'm 67 percent sure, this show right)
	{
		this.int64steam[LOW32BITS] = this.int64steam[HIGH32BITS] = 0;
		this.steamid3[0] = '\0';
		this.steamid2[0] = '\0';
		this.steam64[0] = '\0';

		//if(this.type != 1) return; // This part should limit only for "individual" account types [U:1:2]. Lets run it anyway

		switch(this.type)
		{
			case 0,1,3,5,6,7,10:
			{
				Format(this.steamid3, sizeof(this.steamid3), "[%s:%i:%i]", AccountTypeChar[this.type], this.universe, this.id);
			}
			case 2,4: // accounts with instance serial
			{
				Format(this.steamid3, sizeof(this.steamid3), "[%s:%i:%i:%i]", AccountTypeChar[this.type], this.universe, this.id, this.instance);
			}
			case 8: // chat accounts
			{
				char letter[1];
				letter[0] = AccountTypeChar[this.type][0];

				if(this.instance & 0x80000) //ChatInstanceFlagClan
				{
					letter[0] = 'c';
				}
				else if(this.instance & 0x40000) //ChatInstanceFlagLobby
				{
					letter[0] = 'L';
				}

				// third flag 0x20000 has something to do (MM) MatchMaking chat I guess ?

				Format(this.steamid3, sizeof(this.steamid3), "[%s:%i:%i]", letter, this.universe, this.id);
			}
			default:
			{
				Format(this.steamid3, sizeof(this.steamid3), "[i:%i:%i]", this.universe, this.id);
			}
		}

		Format(this.steamid2, sizeof(this.steamid2), "STEAM_%i:%i:%i", this.instance, this.id % 2, this.id / 2);

		this.int64steam[LOW32BITS] = this.id; //(Low32bits)
		//this.int64steam[HIGH32BITS] = this.data; //High32bits, includes instance, type and universe
		this.int64steam[HIGH32BITS]	= this.instance;
		this.int64steam[HIGH32BITS]	|= (this.type << 20);
		this.int64steam[HIGH32BITS]	|= (this.universe << 24);

		Int64ToString(this.int64steam, this.steam64, sizeof(this.steam64));
	}
}

enum struct IPFilter
{
	int mask;		//0xFF 0xFF 0xFF 0xFF
	int compare;		//0x00 0x00 0x00 0x00
	float banEndTime;	//bantime * 60.0 + GetEngineTime() (when permanent ban, this time is 0.0)
	float banTime;	// 0.0 is permanent ban

	char IP[20];

	void render() //remember execute this to get IP string
	{
		this.IP[0] = '\0';

		int result = this.compare & this.mask;
		Format(this.IP, sizeof(this.IP), "%i.%i.%i.%i",
								result & 0x000000FF,
								(result & 0x0000FF00) >> 8,
								(result & 0x00FF0000) >> 16,
								(result & 0xFF000000) >> 24);
	}

	void clear()
	{
		this.mask = 0;
		this.compare = 0;
		this.banEndTime = 0.0;
		this.banTime = 0.0;
		this.IP[0] = '\0';
	}
}

enum struct UserFilter
{
	int IDType;			//ID type, there are other type IDs beside steam

	SteamID steam;

	float banEndTime;		//bantime * 60.0 + GetEngineTime() (when permanent ban, this time is 0.0)
	float banTime;		// 0.0 is permanent ban

	void clear()
	{
		this.steam.id = 0;
		this.steam.instance = 0;
		this.steam.type = 0;
		this.steam.universe = 0;
		this.steam.data = 0;

		this.banEndTime = 0.0;
		this.banTime = 0.0;

		this.steam.int64steam[LOW32BITS] = this.steam.int64steam[HIGH32BITS] = 0;
		this.steam.steamid3[0] = '\0';
		this.steam.steamid2[0] = '\0';
		this.steam.steam64[0] = '\0';
	}
}

//for addresses array
enum
{
	adr_banned_user_count = 0,
	adr_banned_user_array_size,
	adr_banned_user_array,
	adr_banned_IP_count,
	adr_banned_IP_array_size,
	adr_banned_IP_array,

	adr_banned_user_max,
	adr_banned_IP_max
}
Address addresses[8]; // Store addresses

public void OnPluginStart()
{
	//GameData gamedata = new GameData("test");
	GameData gamedata = new GameData("listid listip debug");

	if(gamedata == null) SetFailState("gamedata failed 'listid listip debug.txt'");

	Address addr = gamedata.GetAddress("banned_user_count_address");
	addresses[adr_banned_user_max]		= gamedata.GetAddress("banned_user_max_address");
	addresses[adr_banned_IP_max]		= gamedata.GetAddress("banned_IP_max_address");

//both ban lists are limited to max 32768 bans
//- you can try play by editing value from memory, example increase to +350 000 bans
	PrintToServer("%08X = MAX banned user %i", addresses[adr_banned_user_max], LoadFromAddress(addresses[adr_banned_user_max], NumberType_Int32));
	PrintToServer("%08X = MAX banned IP %i", addresses[adr_banned_IP_max], LoadFromAddress(addresses[adr_banned_IP_max], NumberType_Int32));


	if(addr == Address_Null) SetFailState("gamedata failed address 'banned_user_count_address'");

	addr = LoadFromAddress(addr, NumberType_Int32);	// load address from banid callback *update
	addresses[adr_banned_user_count]		= addr;	// banned_user_count address
	addresses[adr_banned_user_array_size]	= addr + view_as<Address>(gamedata.GetOffset("banned_user_array_size_offset"));
	addresses[adr_banned_user_array]		= addr + view_as<Address>(gamedata.GetOffset("banned_user_array_offset"));
	addresses[adr_banned_IP_count]		= addr + view_as<Address>(gamedata.GetOffset("banned_IP_count_offset"));
	addresses[adr_banned_IP_array_size]	= addr + view_as<Address>(gamedata.GetOffset("banned_IP_array_size_offset"));
	addresses[adr_banned_IP_array]		= addr + view_as<Address>(gamedata.GetOffset("banned_IP_array_offset"));


	//extra example
	RegConsoleCmd("sm_steamid", cmd_steamid);


	//update info automatically in console, 30 seconds repeat
	CreateTimer(30.0, repeat, _, TIMER_REPEAT);
	repeat(INVALID_HANDLE);
}

public Action repeat(Handle timer)
{
	static int scroll_No = 0;
	scroll_No++;

	char scroll_Time[255];
	FormatTime(scroll_Time, sizeof(scroll_Time), NULL_STRING);

	//	Banned user list
	PrintToServer("\n\n\n		|=======%i========== Scroll %s ========================|", scroll_No, scroll_Time);

	PrintToServer("	----------    Update addresses  (User)  ----------");

	int banneduser_count	= LoadFromAddress(addresses[adr_banned_user_count], NumberType_Int32);
	int banneduser_size	= LoadFromAddress(addresses[adr_banned_user_array_size], NumberType_Int32);
	Address banneduser	= LoadFromAddress(addresses[adr_banned_user_array], NumberType_Int32);


	PrintToServer("\n%X = banneduser_count %i	(active bans, doesn't expire in real time)",	addresses[adr_banned_user_count], banneduser_count);
	PrintToServer("%X = banneduser_size %i	(dynamic array size)",								addresses[adr_banned_user_array_size], banneduser_size);
	PrintToServer("%X = banneduser %08X	(dynamic array address)\n",								addresses[adr_banned_user_array], banneduser);

	PrintToServer("	---------- banned user list - \"Once upon a time...\" ----------");

	if(!banneduser_count)	PrintToServer("        *empty*");

	UserFilter userfilter;
	Address banneduser_index;
	float expire;

	// loop max 3 last ban from whole ban list instead read all
	for(int x = (banneduser_count > 3 ? banneduser_count-3:0);
		x < banneduser_count;
		x++)
	{
		banneduser_index			= view_as<Address>(0x14 * x); //array index, banned user data is 20bytes long

		userfilter.clear(); // remove any previous data
		expire = 0.0;

		userfilter.IDType			= LoadFromAddress(banneduser + banneduser_index, NumberType_Int32);
		userfilter.steam.id		= LoadFromAddress(banneduser + banneduser_index + view_as<Address>(0x4), NumberType_Int32);
		userfilter.steam.data		= LoadFromAddress(banneduser + banneduser_index + view_as<Address>(0x8), NumberType_Int32);
		userfilter.banEndTime		= LoadFromAddress(banneduser + banneduser_index + view_as<Address>(0xC), NumberType_Int32);
		userfilter.banTime		= LoadFromAddress(banneduser + banneduser_index + view_as<Address>(0x10), NumberType_Int32);

		userfilter.steam.extractdata(); //fill missing details
		userfilter.steam.render();	//create steam3 string with given data (output userfilter.steam.steamid3)

		PrintToServer("\n[%i/%i] banned user index", x+1, banneduser_count);
		PrintToServer("userfilter.IDType %i\n", userfilter.IDType);

		PrintToServer("userfilter.steam.id	0x%08X (Low32bits)", userfilter.steam.id);
		PrintToServer("userfilter.steam.data	0x%08X (High32bits)\n", userfilter.steam.data);
		PrintToServer("userfilter.steam.instance	%i", userfilter.steam.instance);
		PrintToServer("userfilter.steam.type		%i", userfilter.steam.type);
		PrintToServer("userfilter.steam.universe	%i\n", userfilter.steam.universe);
		PrintToServer("userfilter.steam.steamid3	%s", userfilter.steam.steamid3);
		PrintToServer("userfilter.steam.steamid2	%s", userfilter.steam.steamid2);
		PrintToServer("userfilter.steam.steam64	%s", userfilter.steam.steam64);

		//print profile URL only on steam-single-user-account
		if(userfilter.IDType == 1 && userfilter.steam.type == 1) PrintToServer("http://steamcommunity.com/profiles/%s", userfilter.steam.steam64);

		if(userfilter.banEndTime != 0.0 && userfilter.banTime != 0.0) // if not permanent
		{
			expire = userfilter.banEndTime - GetEngineTime();
			PrintToServer("\nuserfilter.banEndTime	%f %s%f%s", userfilter.banEndTime, expire < 0.0 ? "(expired ":"(expire in ", expire, expire < 0.0 ? " seconds ago)":" seconds)");
		}
		else
		{
			PrintToServer("\nuserfilter.banEndTime	%f \"permanent\"", userfilter.banEndTime);
		}
		PrintToServer("userfilter.banTime	%0.2f (command ban duration, minutes)\n", userfilter.banTime);

		PrintToServer("%08X = whole data in memory space = %08X%08X%08X%08X%08X", banneduser + banneduser_index,
		convertEndian(userfilter.IDType),
		convertEndian(userfilter.steam.id),
		convertEndian(userfilter.steam.data),
		convertEndian(view_as<int>(userfilter.banEndTime)),
		convertEndian(view_as<int>(userfilter.banTime)));
	}

	PrintToServer("	---------- banned user list - \"...happily ever after. The End\" ----------");



	// Banned IP list
	PrintToServer("\n\n	----------    Update addresses  (IP) ----------");

	int bannedIP_count	= LoadFromAddress(addresses[adr_banned_IP_count], NumberType_Int32);
	int bannedIP_size		= LoadFromAddress(addresses[adr_banned_IP_array_size], NumberType_Int32);
	Address bannedIP		= LoadFromAddress(addresses[adr_banned_IP_array], NumberType_Int32);

	PrintToServer("\n%X = bannedIP_count %i	(active bans, doesn't expire in real time)",	addresses[adr_banned_IP_count], bannedIP_count);
	PrintToServer("%X = bannedIP_size %i	(dynamic array size)",							addresses[adr_banned_IP_array_size], bannedIP_size);
	PrintToServer("%X = bannedIP %08X	(dynamic array address)\n",							addresses[adr_banned_IP_array], bannedIP);

	PrintToServer("	---------- banned IP list - \"Once upon a time...\" ----------");

	if(!bannedIP_count) PrintToServer("        *empty*");

	IPFilter ipfilter;
	Address ipfilter_index;
	//float expire;

	// loop max 3 last ban from whole ban base instead read all
	for(int x = (bannedIP_count > 3 ? bannedIP_count-3:0);
		x < bannedIP_count;
		x++)
	{
		ipfilter_index			= view_as<Address>(0x10 * x); //array index, banned IP data is 16bytes long

		ipfilter.clear(); // remove any previous data
		expire = 0.0;

		ipfilter.mask		= LoadFromAddress(bannedIP + ipfilter_index, NumberType_Int32);
		ipfilter.compare		= LoadFromAddress(bannedIP + ipfilter_index + view_as<Address>(0x4), NumberType_Int32);
		ipfilter.banEndTime	= LoadFromAddress(bannedIP + ipfilter_index + view_as<Address>(0x8), NumberType_Int32);
		ipfilter.banTime		= LoadFromAddress(bannedIP + ipfilter_index + view_as<Address>(0xC), NumberType_Int32);

		ipfilter.render();	//create IP string with given compare & mask (output ipfilter.IP)

		PrintToServer("\n[%i/%i] banned IP index", x+1, bannedIP_count);
		PrintToServer("ipfilter.mask %08X", ipfilter.mask);
		PrintToServer("ipfilter.compare %08X\n", ipfilter.compare);

		PrintToServer("ipfilter.IP	%s\n", ipfilter.IP);

		if(ipfilter.banEndTime != 0.0 && ipfilter.banTime != 0.0) // if not permanent
		{
			expire = ipfilter.banEndTime - GetEngineTime();
			PrintToServer("\nipfilter.banEndTime	%f %s%f%s", ipfilter.banEndTime, expire < 0.0 ? "(expired ":"(expire in ", expire, expire < 0.0 ? " seconds ago)":" seconds)");
		}
		else
		{
			PrintToServer("\nipfilter.banEndTime	%f \"permanent\"", ipfilter.banEndTime);
		}
		PrintToServer("ipfilter.banTime	%0.2f (command ban duration, minutes)\n", ipfilter.banTime);

		PrintToServer("%08X = whole data in memory space = %08X%08X%08X%08X", bannedIP + ipfilter_index,
		convertEndian(ipfilter.mask),
		convertEndian(ipfilter.compare),
		convertEndian(view_as<int>(ipfilter.banEndTime)),
		convertEndian(view_as<int>(ipfilter.banTime)));
	}

	PrintToServer("	---------- banned IP list - \"...happily ever after. The End\" ----------");
	PrintToServer("		|=========================================================|");

	return Plugin_Continue;
}

public Action cmd_steamid(int client, int args)
{
	if(client == 0)
		return Plugin_Continue;

	char auth[64];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));

	if(StrContains(auth, "STEAM_", true) == 0 && auth[7] == ':')
	{
		SteamID steam;

		steam.id = StringToInt(auth[8]) + StringToInt(auth[10]) * 2; //Low32bits

		//High32bits (we need fill missing details manually)
		steam.instance = INSTANCE_DESKTOP; //StringToInt(auth[6]); //game (mod) engine may render "instance" output always as zero.
		steam.type = 1; // individual, single user 'U'
		steam.universe = 1; // public

		steam.render();

		ReplyToCommand(client, "%s\n%s\n%s", steam.steamid2, steam.steamid3, steam.steam64);
	}


	return Plugin_Handled;
}



stock int convertEndian(int value) // change Endian bytes order (Little Endian <-> Big Endian)
{
	int converted = 0;
	converted |= ((0x000000ff & value) << 24);
	converted |= ((0x0000ff00 & value) << 8);
	converted |= ((0x00ff0000 & value) >> 8);
	converted |= ((0xff000000 & value) >> 24);
	return converted;
}