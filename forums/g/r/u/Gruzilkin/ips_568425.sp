#include <sourcemod>
 
new Handle:cvarAllowSelfRegister=INVALID_HANDLE;
new Handle:cvarAllowListing=INVALID_HANDLE;

new Handle:kv_steam;
new Handle:kv_lan;
new Handle:kv_internet;
new Handle:g_visiblemaxplayers
 
public Plugin:myinfo = {
	name = "IP and SteamID Reserved Slots",
	author = "Gruzilkin",
	description = "Controls reserved slots using IP ranges and SteamID",
	version = "1.2",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	cvarAllowSelfRegister = CreateConVar("sm_ips_allowselfregister", "1", "Toggles selfregister option");
	cvarAllowListing = CreateConVar("sm_ips_allowlisting", "1", "Toggles listing option");
	RegConsoleCmd("say", Command_Say)

	kv_steam = CreateKeyValues("SteamIDBase")
	FileToKeyValues(kv_steam , "steamid.txt");

	kv_lan = CreateKeyValues("IPBase");
	FileToKeyValues(kv_lan, "lan.txt");
	
	kv_internet = CreateKeyValues("IPBase");
	FileToKeyValues(kv_internet, "internet.txt");

	g_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
}

public OnPluginEnd()
{
	KeyValuesToFile(kv_steam, "steamid.txt");
	CloseHandle(kv_steam);

	KeyValuesToFile(kv_lan, "lan.txt");
	CloseHandle(kv_lan);

	KeyValuesToFile(kv_internet, "internet.txt");
	CloseHandle(kv_internet);

	CloseHandle(g_visiblemaxplayers)
}
 
public Action:Command_Say(client, args)
{
	new bool:allowSelfRegister = GetConVarBool(cvarAllowSelfRegister);
	new bool:allowListing = GetConVarBool(cvarAllowListing);
	if( allowSelfRegister || allowListing ) {
		new String:text[192]
		GetCmdArgString(text, sizeof(text))
 
		new startidx = 0
		if (text[0] == '"')
		{
			startidx = 1
			/* Strip the ending quote, if there is one */
			new len = strlen(text);
			if (text[len-1] == '"')
			{
				text[len-1] = '\0'
			}
		}
 
		if (allowListing  && StrEqual(text[startidx], "ips"))
		{
			PrintToChat(client, "\x04 NAME   ------   \x01IP\x04   ------   LAN");
			new maxClients = GetMaxClients();
			decl String:name[64];
			decl String:ipadress[64];
			decl String:LANname[64];
			for (new i = 1; i <= maxClients; i++)
			{
				if (IsClientInGame(i))
				{
					GetClientIP(i, ipadress, sizeof(ipadress));
					GetClientName(i, name, sizeof(name));
					GetClientLAN(i, LANname, sizeof(LANname));
					PrintToChat(client, "\x04 %s  \x01 %s  \x04 %s", name, ipadress, LANname);
				}
			}
			return Plugin_Handled
		}

		if (allowSelfRegister  && StrEqual(text[startidx], "regme"))
		{
			decl String:SteamID[64];
			GetClientAuthString(client, SteamID, 64);

			if (!KvJumpToKey(kv_steam, SteamID))
			{
				KvJumpToKey(kv_steam, SteamID, true);
				KvSetNum(kv_steam,"Registered",1);
				PrintToChat(client, "\x04Your SteamID has been registered");
			}
			else {
				PrintToChat(client, "\x04You already have a reserved slot ");
			
			}
			KvRewind(kv_steam);
			return Plugin_Handled
		}
	}
 
	/* Let say continue normally */
	return Plugin_Continue
}

public OnClientPostAdminFilter(client)
{
	decl String:auth[20];
	GetClientAuthString(client, auth, 20);
	if(strcmp(auth, "BOT") == 0) return Plugin_Continue;

	decl String:name[64];
	decl String:ipadress[64];
	decl String:LANname[64];
	GetClientIP(client, ipadress, sizeof(ipadress));
	GetClientName(client, name, sizeof(name));
	GetClientLAN(client, LANname, sizeof(LANname));

	new playercount = GetClientCount(false);

	new visiblemaxplayers = GetConVarInt(g_visiblemaxplayers);


	if (visiblemaxplayers > 0 && playercount > visiblemaxplayers) {
		if (strcmp(LANname, "Internet") ==0 ) {
			if (!KvJumpToKey(kv_steam, auth))
			{
				KvRewind(kv_steam);

				return Plugin_Continue;
			}
			KvRewind(kv_steam);
		}
	}
	new clientFlags = 0;
	clientFlags = GetUserFlagBits(client);
	clientFlags|= ADMFLAG_RESERVATION;
	SetUserFlagBits(client, clientFlags);


	if (GetConVarBool(cvarAllowListing)) PrintToChatAll("\x01 Player \x04 %s  \x01 is connecting from \x04 %s \x01 (\x04%s\x01)", name, ipadress, LANname);
	PrintToServer("\x01 Player \x04 %s  \x01 is connecting from \x04 %s \x01 (\x04%s\x01)", name, ipadress, LANname);	

	return Plugin_Continue;
}

public bool:GetClientLAN (client, String:LANname[], maxlength)
{
	decl String:buffers[4][5]
	decl String:ipadress[64];
	GetClientIP(client, ipadress, sizeof(ipadress));
	if(strcmp(ipadress, "127.0.0.1") == 0) {
		strcopy (LANname, maxlength, "BOT");
		return true;
	}
	ExplodeString(ipadress, ".", buffers, 4, 5);
	new first_byte = StringToInt(buffers[0]);
	

	new Handle:kv_tmp
	if (first_byte == 10 || first_byte == 192 || first_byte == 172) kv_tmp = kv_lan;
	else kv_tmp = kv_internet;
 
	if (!KvGotoFirstSubKey(kv_tmp))
	{
		PrintToChat(client, "DB not found");
		return false;
	}
 
	decl String:buffer[255]
	decl String:IPStart[20]
	decl String:IPEnd[20]
	do
	{
		KvGetString(kv_tmp, "ip1", IPStart, 20)
		KvGetString(kv_tmp, "ip2", IPEnd, 20)
		if ( CheckIP(ipadress, IPStart, IPEnd) ) {
			KvGetSectionName(kv_tmp, buffer, sizeof(buffer));
			KvRewind(kv_tmp);
			decl String:name[1][255];
			ExplodeString(buffer, "*", name, 1, 255);
			strcopy(LANname, maxlength, name[0]);
			return true;
		}
	} while (KvGotoNextKey(kv_tmp))
	KvRewind(kv_tmp);
	return false;
}

public bool:CheckIP (String:IP[], String:IPStart[], String:IPEnd[])
{
	decl String:buffers[3][4][5]
	ExplodeString(IP, ".", buffers[0], 4, 5);
	ExplodeString(IPStart, ".", buffers[1], 4, 5);
	ExplodeString(IPEnd, ".", buffers[2], 4, 5);
	new i;
	for(i=0 ; i<4 ; i++) {
		if( (StringToInt(buffers[0][i]) < StringToInt(buffers[1][i])) || (StringToInt(buffers[0][i]) > StringToInt(buffers[2][i]))) return false;
	}
	return true;
}