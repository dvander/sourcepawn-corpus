#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Colortext",
	author = "Alienmario",
	description = "Changes the color of chat messages for everyone",
	version = "1.2",
}

new Handle:colortext_enabletp = INVALID_HANDLE;
new Handle:colortext_namecolor = INVALID_HANDLE;
new Handle:colortext_textcolor = INVALID_HANDLE;
new Handle:colortext_cmdcolor = INVALID_HANDLE;
new Handle:colortext_cmdcolor_enable = INVALID_HANDLE;
new bool:tp;

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("SayText2"), TextMsg, true);
	colortext_enabletp  = CreateConVar("colortext_enabletp","0","Enable colored chat text when mp_teamplay=1",FCVAR_PLUGIN, true, 0.0, true, 1.0);
	colortext_namecolor  = CreateConVar("colortext_namecolor","87CEEB","hex color of player names",FCVAR_PLUGIN);
	colortext_textcolor  = CreateConVar("colortext_textcolor","FFFFFF","hex color of player's text",FCVAR_PLUGIN);
	colortext_cmdcolor  = CreateConVar("colortext_cmdcolor","AAAAAA","hex color of player's command triggers",FCVAR_PLUGIN);
	colortext_cmdcolor_enable  = CreateConVar("colortext_cmdcolor_enable","1","enable coloring player's command triggers",FCVAR_PLUGIN, true, 0.0, true, 1.0);
	AutoExecConfig();
}

public OnMapStart(){
	new Handle:hTp=FindConVar("mp_teamplay");
	if(hTp==INVALID_HANDLE){
		ThrowError("failed to find mp_teamplay convar");
	}else{
		tp=GetConVarBool(hTp);
		CloseHandle(hTp);
	}
}

public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(reliable)
	{
		new author = BfReadByte (bf);
		new chatmsg = BfReadByte (bf);
		
		char cpTranslationName[32];
		BfReadString (bf, cpTranslationName, sizeof(cpTranslationName));
		
		char cpSender_Name[32];
		BfReadString(bf, cpSender_Name, sizeof(cpSender_Name));
		
		char buffer[256];
		BfReadString(bf, buffer, sizeof(buffer));
		
		//PrintToServer("author %d, chatmsg %d, trans %s, sender %s, buffer %s", author, chatmsg, cpTranslationName, cpSender_Name, buffer);
		
		if(!GetConVarBool(colortext_enabletp) && tp){
			if(!StrContains(buffer[0], "!") && GetConVarBool(colortext_cmdcolor_enable))
			{
			// is a trigger
			}else{
				return Plugin_Continue;
			}
		}
		new Handle:pack;
		CreateDataTimer(0.0, writeMsg, pack);

		WritePackCell(pack, author);
		WritePackCell(pack, chatmsg);
		WritePackCell(pack, playersNum);
		for(new i = 0; i < playersNum; i++)
		{
			WritePackCell(pack, players[i]);
		}
		WritePackString(pack, cpTranslationName);
		WritePackString(pack, buffer);
		ResetPack(pack);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:writeMsg(Handle:timer, Handle:pack)
{
	new author = ReadPackCell(pack);
	new chatmsg = ReadPackCell(pack);
	new playersNum = ReadPackCell(pack);
	new players[playersNum];
	new client, count;

	for(new i = 0; i < playersNum; i++)
	{
		client = ReadPackCell(pack);
		if(IsClientInGame(client))
		{
			players[count++] = client;
		}
	}

	if(count < 1) return;
	
	playersNum = count;
	
	char cpTranslationName[32];
	ReadPackString(pack, cpTranslationName, sizeof(cpTranslationName));
	
	char preString[13];
	
	if(StrEqual(cpTranslationName, "HL2MP_Chat_Team")){
		preString = "(TEAM) ";
	} else if (StrEqual(cpTranslationName, "HL2MP_Chat_AllSpec")){
		preString = "*SPEC* ";
	} else if (StrEqual(cpTranslationName, "HL2MP_Chat_Spec")){
		preString = "(Spectator) ";
	}
	
	char buffer[256];
	ReadPackString(pack, buffer, sizeof(buffer));

	if(!StrContains(buffer[0], "!") && GetConVarBool(colortext_cmdcolor_enable)){ //is a trigger
		char cCmd[7];
		GetConVarString(colortext_cmdcolor, cCmd, sizeof(cCmd));
		Format(buffer, sizeof(buffer), "\x07%s%s%N : \x07%s%s", cCmd, preString, author, cCmd, buffer);
	} else {
		char cText[7];
		char cName[7];
		GetConVarString(colortext_namecolor, cName, sizeof(cName));
		GetConVarString(colortext_textcolor, cText, sizeof(cText));
		
		if(StrEqual(cName, "team", false)){
			Format(buffer, sizeof(buffer), "\x01%s\x03%N : \x07%s%s", preString, author, cText, buffer);
		} else {
			Format(buffer, sizeof(buffer), "\x01%s\x07%s%N : \x07%s%s", preString, cName, author, cText, buffer);
		}
	}
	new Handle:bf = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, author);
	BfWriteByte(bf, chatmsg);
	BfWriteString(bf, buffer);
	EndMessage();
}