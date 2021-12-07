new Handle:g_PrefixName  = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "SM Prefix Change",
	author = "dkzinhoo",
	description = "Change SM PREFIX",
	version = "v7",
};

public OnPluginStart() 
{ 
	if(GetUserMessageType() == UM_Protobuf) 
	{ 
		HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true); 
	} 
	g_PrefixName = CreateConVar("sm_prefix_name", "[Battles]", "Set your prefix name.", FCVAR_PLUGIN);
} 

public Action:TextMsg(UserMsg:msg_id, Handle:pb, players[], playersNum, bool:reliable, bool:init) 
{ 
    if(!reliable || PbReadInt(pb, "msg_dst") != 3) 
    { 
        return Plugin_Continue; 
    } 

    new String:buffer[256]; 
    PbReadString(pb, "params", buffer, sizeof(buffer), 0); 

    if(StrContains(buffer, "[SM] ") == 0) 
    { 
        new Handle:pack; 
        CreateDataTimer(0.0, change_prefix, pack, TIMER_FLAG_NO_MAPCHANGE); 
        WritePackCell(pack, playersNum); 
        for(new i = 0; i < playersNum; i++) 
        { 
            WritePackCell(pack, players[i]); 
        } 
        WritePackCell(pack, strlen(buffer)); 
        WritePackString(pack, buffer); 
        ResetPack(pack); 

        return Plugin_Handled; 
    } 

    return Plugin_Continue; 
} 

public Action:change_prefix(Handle:timer, Handle:pack) 
{ 
	new playersNum = ReadPackCell(pack); 
	new players[playersNum]; 
	new player, players_count; 

	for(new i = 0; i < playersNum; i++) 
	{ 
		player = ReadPackCell(pack); 

		if(IsClientInGame(player)) 
		{ 
			players[players_count++] = player; 
		} 
	} 

	playersNum = players_count; 

	if(playersNum < 1) 
	{ 
		return; 
	} 

	new Handle:pb = StartMessage("TextMsg", players, playersNum, USERMSG_BLOCKHOOKS); 
	PbSetInt(pb, "msg_dst", 3); 

	new buffer_size = ReadPackCell(pack)+15; 
	new String:buffer[buffer_size]; 
	ReadPackString(pack, buffer, buffer_size); 
	decl String:sBuffer[32];
	GetConVarString(g_PrefixName, sBuffer, sizeof(sBuffer));
	Format(buffer, buffer_size, " \x04%s\x01%s", sBuffer,buffer[4]);

	PbAddString(pb, "params", buffer); 
	PbAddString(pb, "params", NULL_STRING); 
	PbAddString(pb, "params", NULL_STRING); 
	PbAddString(pb, "params", NULL_STRING); 
	PbAddString(pb, "params", NULL_STRING); 
	EndMessage(); 
}  