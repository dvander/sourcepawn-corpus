//Includes:
#include <sourcemod>
#include <sdktools>

//Terminate:
#pragma semicolon 1

//Information:
public Plugin:myinfo =
{
	
	//Initialize:
	name = "Admin Connect",
	author = "Benjamin1995 aka Benni",
	description = "Admin and Cop Connecter",
	version = "1.1",
	url = "http://www.bfs-server.de"
}



static String:SoundPath[64];


static JoinSound[33];

//Initation:
public OnPluginStart()
{
	RegAdminCmd("sm_setjoinsound", CommandSetJoinSound, ADMFLAG_ROOT, "Point and go");
	RegAdminCmd("sm_deletejoinsound", CommandDeleteJoinSound, ADMFLAG_ROOT, "Point and go");
	RegAdminCmd("sm_setcopjoinsound", CommandSetCopJoinSound, ADMFLAG_ROOT, "Point and go");
	RegAdminCmd("sm_setcustomjoinsound", CommandSetCustomJoinSound, ADMFLAG_ROOT, "Point and go");
	//Join DB:
	BuildPath(Path_SM, SoundPath, 64, "data/connect/joinsounds.txt");
	if(FileExists(SoundPath) == false) PrintToConsole(0, "[SM] ERROR: Missing file '%s'", SoundPath);
	//Server Variable:
	CreateConVar("benni_connect_version", "1.1", "Benni Admin Connect",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	
}


public Action:CommandSetCustomJoinSound(Client, Args)
{
	
	//Error:
	if(Args < 2)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_setcustomjoinsound <name> <sound> ");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl MaxPlayers, Player;
	decl String:Sound[255];
	decl String:PlayerName[32];
	decl String:Name[32];
	
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	GetCmdArg(2, Sound, sizeof(Sound));
	
	//Find:
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers; X++)
	{
		
		//Connected:
		if(!IsClientConnected(X)) continue;
		
		//Initialize:
		GetClientName(X, Name, sizeof(Name));
		
		//Save:
		if(StrContains(Name, PlayerName, false) != -1) Player = X;
	}
	
	//Invalid Name:
	if(Player == -1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Could not find client %s", PlayerName);
		
		//Return:
		return Plugin_Handled;
	}
	
	
	decl String:SteamId2[255];
	GetClientAuthString(Player, SteamId2, 32);
	
	
	
	
	
	
	
	
	
	decl Handle:Vault6;	
	Vault6 = CreateKeyValues("Vault6");
	FileToKeyValues(Vault6, SoundPath);	
	KvJumpToKey(Vault6, "ConnectSound", true);
	KvSetString(Vault6, SteamId2, Sound);	
	KvRewind(Vault6);	
	KeyValuesToFile(Vault6, SoundPath);	
	CloseHandle(Vault6);
	
	decl Handle:Vault7;	
	Vault7 = CreateKeyValues("Vault7");
	FileToKeyValues(Vault7, SoundPath);	
	KvJumpToKey(Vault7, "OwnSound", true);
	KvSetString(Vault7, SteamId2, "3");	
	KvRewind(Vault7);	
	KeyValuesToFile(Vault7, SoundPath);	
	CloseHandle(Vault7);
	
	
	new String:pname[80];
	GetClientName(Player, pname, 80);	
	new String:sname[80];
	GetClientName(Client, sname, 80);	
	
	
	PrintToChat(Client, "\x04\x01[RP] You set \x04%s\x04\x01 a sound \"\x04%s\x04\"", pname, Sound);
	PrintToChat(Player, "\x04\x01[RP] \x04%s\x04\x01 set you the sound \"\x04%s\x04\"", sname, Sound);
	
	
	
	
	
	return Plugin_Handled;
}

public Action:CommandSetJoinSound(Client, Args)
{
	
	//Error:
	if(Args < 2)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_setjoinsound <name> <sound> ");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl MaxPlayers, Player;
	decl String:Sound[255];
	decl String:PlayerName[32];
	decl String:Name[32];
	
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	GetCmdArg(2, Sound, sizeof(Sound));
	
	//Find:
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers; X++)
	{
		
		//Connected:
		if(!IsClientConnected(X)) continue;
		
		//Initialize:
		GetClientName(X, Name, sizeof(Name));
		
		//Save:
		if(StrContains(Name, PlayerName, false) != -1) Player = X;
	}
	
	//Invalid Name:
	if(Player == -1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Could not find client %s", PlayerName);
		
		//Return:
		return Plugin_Handled;
	}
	
	
	decl String:SteamId2[255];
	GetClientAuthString(Player, SteamId2, 32);
	
	
	
	
	
	
	
	
	
	decl Handle:Vault6;	
	Vault6 = CreateKeyValues("Vault6");
	FileToKeyValues(Vault6, SoundPath);	
	KvJumpToKey(Vault6, "ConnectSound", true);
	KvSetString(Vault6, SteamId2, Sound);	
	KvRewind(Vault6);	
	KeyValuesToFile(Vault6, SoundPath);	
	CloseHandle(Vault6);
	
	decl Handle:Vault7;	
	Vault7 = CreateKeyValues("Vault7");
	FileToKeyValues(Vault7, SoundPath);	
	KvJumpToKey(Vault7, "OwnSound", true);
	KvSetString(Vault7, SteamId2, "1");	
	KvRewind(Vault7);	
	KeyValuesToFile(Vault7, SoundPath);	
	CloseHandle(Vault7);
	
	
	new String:pname[80];
	GetClientName(Player, pname, 80);	
	new String:sname[80];
	GetClientName(Client, sname, 80);	
	
	
	PrintToChat(Client, "\x04\x01[RP] You set \x04%s\x04\x01 a sound \"\x04%s\x04\"", pname, Sound);
	PrintToChat(Player, "\x04\x01[RP] \x04%s\x04\x01 set you the sound \"\x04%s\x04\"", sname, Sound);
	
	
	
	
	
	return Plugin_Handled;
}




public Action:CommandSetCopJoinSound(Client, Args)
{
	
	//Error:
	if(Args < 2)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_setcopsound <name> <sound> ");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl MaxPlayers, Player;
	decl String:Sound[255];
	decl String:PlayerName[32];
	decl String:Name[32];
	
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	GetCmdArg(2, Sound, sizeof(Sound));
	
	//Find:
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers; X++)
	{
		
		//Connected:
		if(!IsClientConnected(X)) continue;
		
		//Initialize:
		GetClientName(X, Name, sizeof(Name));
		
		//Save:
		if(StrContains(Name, PlayerName, false) != -1) Player = X;
	}
	
	//Invalid Name:
	if(Player == -1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Could not find client %s", PlayerName);
		
		//Return:
		return Plugin_Handled;
	}
	
	
	decl String:SteamId2[255];
	GetClientAuthString(Player, SteamId2, 32);
	
	
	
	
	
	
	
	
	
	decl Handle:Vault6;	
	Vault6 = CreateKeyValues("Vault6");
	FileToKeyValues(Vault6, SoundPath);	
	KvJumpToKey(Vault6, "ConnectSound", true);
	KvSetString(Vault6, SteamId2, Sound);	
	KvRewind(Vault6);	
	KeyValuesToFile(Vault6, SoundPath);	
	CloseHandle(Vault6);
	
	decl Handle:Vault7;	
	Vault7 = CreateKeyValues("Vault7");
	FileToKeyValues(Vault7, SoundPath);	
	KvJumpToKey(Vault7, "OwnSound", true);
	KvSetString(Vault7, SteamId2, "2");	
	KvRewind(Vault7);	
	KeyValuesToFile(Vault7, SoundPath);	
	CloseHandle(Vault7);
	
	
	new String:pname[80];
	GetClientName(Player, pname, 80);	
	new String:sname[80];
	GetClientName(Client, sname, 80);	
	
	
	PrintToChat(Client, "\x04\x01[RP] You set \x04%s\x04\x01 a sound \"\x04%s\x04\"", pname, Sound);
	PrintToChat(Player, "\x04\x01[RP] \x04%s\x04\x01 set you the sound \"\x04%s\x04\"", sname, Sound);
	
	
	
	
	
	return Plugin_Handled;
}


public Action:CommandDeleteJoinSound(Client, Args)
{
	
	//Error:
	if(Args < 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_setjoinsound <name> <sound> ");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl MaxPlayers, Player;
	decl String:Sound[255];
	decl String:PlayerName[32];
	decl String:Name[32];
	
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	GetCmdArg(2, Sound, sizeof(Sound));
	
	//Find:
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers; X++)
	{
		
		//Connected:
		if(!IsClientConnected(X)) continue;
		
		//Initialize:
		GetClientName(X, Name, sizeof(Name));
		
		//Save:
		if(StrContains(Name, PlayerName, false) != -1) Player = X;
	}
	
	//Invalid Name:
	if(Player == -1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Could not find client %s", PlayerName);
		
		//Return:
		return Plugin_Handled;
	}
	
	
	decl String:SteamId2[255];
	GetClientAuthString(Player, SteamId2, 32);
	
	
	
	
	
	
	
	
	
	decl Handle:Vault6;	
	Vault6 = CreateKeyValues("Vault6");
	FileToKeyValues(Vault6, SoundPath);	
	KvJumpToKey(Vault6, "ConnectSound", true);
	KvDeleteKey(Vault6, SteamId2);	
	KvRewind(Vault6);	
	KeyValuesToFile(Vault6, SoundPath);	
	CloseHandle(Vault6);
	
	decl Handle:Vault7;	
	Vault7 = CreateKeyValues("Vault7");
	FileToKeyValues(Vault7, SoundPath);	
	KvJumpToKey(Vault7, "OwnSound", true);
	KvDeleteKey(Vault7, SteamId2);	
	KvRewind(Vault7);	
	KeyValuesToFile(Vault7, SoundPath);	
	CloseHandle(Vault7);
	
	
	new String:pname[80];
	GetClientName(Player, pname, 80);	
	new String:sname[80];
	GetClientName(Client, sname, 80);	
	
	
	PrintToChat(Client, "\x04\x01[RP] You deleted \x04%s's\x04\x01 joinsound", pname);
	PrintToChat(Player, "\x04\x01[RP] \x04%s\x04\x01 deleted your joinsound", sname);
	
	
	
	
	
	return Plugin_Handled;
}


public Action:MSG(Handle:Timer, any:Client) {
	new String:sname[80];
	GetClientName(Client, sname, 80);	
	PrintCenterTextAll("Admin %s has connected!", sname);
	PrintToChatAll("\x04\x01Admin \x04%s\x04\x01 has connected!", sname);
	
}
public Action:MSGCOP(Handle:Timer, any:Client) {
	new String:sname[80];
	GetClientName(Client, sname, 80);	
	PrintCenterTextAll("Police Man %s has connected!", sname);
	PrintToChatAll("\x04\x01Police Man \x04%s\x04\x01 has connected!", sname);
	
}

public Action:MSGCUSTOM(Handle:Timer, any:Client) {
	new String:sname[80];
	GetClientName(Client, sname, 80);	
	PrintCenterTextAll("Player %s has connected!", sname);
	PrintToChatAll("\x04\x01Player \x04%s\x04\x01 has connected!", sname);
	
}
public OnClientPostAdminCheck (Client) {
	
	
	decl String:SteamId[255];
	decl String:Sound[255];
	
	GetClientAuthString(Client, SteamId, 32);
	
	decl Handle:Vault;	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, SoundPath);	
	KvJumpToKey(Vault, "OwnSound", true);
	JoinSound[Client] = KvGetNum(Vault, SteamId);	
	KvRewind(Vault);	
	KeyValuesToFile(Vault, SoundPath);	
	CloseHandle(Vault);
	
	
	if(JoinSound[Client] == 1)
	{	
		//To Save:
		Vault = CreateKeyValues("Vault");
		FileToKeyValues(Vault, SoundPath);	
		KvJumpToKey(Vault, "ConnectSound", true);	
		KvGetString(Vault, SteamId, Sound, 255, "null");
		KvRewind(Vault);
		CloseHandle(Vault);
		new String:sname[80];
		GetClientName(Client, sname, 80);	
		CreateTimer(5.0, MSG, Client);
		
		PrecacheSound(Sound, true);
		EmitSoundToAll(Sound, SOUND_FROM_PLAYER, 5);
	}
	
	if(JoinSound[Client] == 2)
	{
		//To Save:
		Vault = CreateKeyValues("Vault");
		FileToKeyValues(Vault, SoundPath);	
		KvJumpToKey(Vault, "ConnectSound", true);	
		KvGetString(Vault, SteamId, Sound, 255, "null");
		KvRewind(Vault);
		CloseHandle(Vault);
		new String:sname[80];
		GetClientName(Client, sname, 80);	
		CreateTimer(5.0, MSGCOP, Client);
		
		PrecacheSound(Sound, true);
		EmitSoundToAll(Sound, SOUND_FROM_PLAYER, 5);
	}
	
	if(JoinSound[Client] == 3)
	{
		//To Save:
		Vault = CreateKeyValues("Vault");
		FileToKeyValues(Vault, SoundPath);	
		KvJumpToKey(Vault, "ConnectSound", true);	
		KvGetString(Vault, SteamId, Sound, 255, "null");
		KvRewind(Vault);
		CloseHandle(Vault);
		new String:sname[80];
		GetClientName(Client, sname, 80);	
		CreateTimer(5.0, MSGCUSTOM, Client);
		
		PrecacheSound(Sound, true);
		EmitSoundToAll(Sound, SOUND_FROM_PLAYER, 5);
	}
	
	
}
