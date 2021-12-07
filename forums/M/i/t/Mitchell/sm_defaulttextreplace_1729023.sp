#include <sourcemod>
#pragma semicolon 1

#define MAXTEXTCOLORS 100

// Plugin definitions
#define PLUGIN_VERSION "0.32"

public Plugin:myinfo =
{
	name = "Default SM Text Replacer",
	author = "Mitch/Bacardi",
	description = "Replaces the '[SM]' text with more color!",
	version = PLUGIN_VERSION,
	url = ""
};
new Handle:cvar_randomcolor = INVALID_HANDLE;
new UseRandomColors = 0;
new CountColors = 0;

new String:TextColors[MAXTEXTCOLORS][256];

public OnPluginStart()
{
	cvar_randomcolor	=	CreateConVar( "sm_textcol_random", "1", "Uses random colors that you defined. 1- random 0-Default" );
	AutoExecConfig(true, "sm_textreplacer");
	HookConVarChange(cvar_randomcolor, Event_CvarChange);
	CreateConVar("sm_textreplacer_version", PLUGIN_VERSION, "text replacer version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_reloadstc", Command_ReloadConfig, ADMFLAG_CONFIG, "Reloads Text color's config file");
	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
}
public Action:Command_ReloadConfig(client, args) {
	
	RefreshConfig();
	LogAction(client, -1, "Reloaded [SM] Text replacer config file");
	ReplyToCommand(client, "[STC] Reloaded config file.");
	return Plugin_Handled;
}
public OnConfigsExecuted()
{
	RefreshConfig();
}

public Event_CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RefreshConfig();
}

stock RefreshConfig()
{
	UseRandomColors = GetConVarInt(cvar_randomcolor);
	for (new X = 0; X < MAXTEXTCOLORS; X++)
	{
		//Format(TextColors[X], sizeof(TextColors), "");
		TextColors[X] = "";
	}
	decl String:sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/sm_textcolors.cfg");
	new Handle:hFile = OpenFile(sPaths, "r");
	new String:sBuffer[256]; 
	//new len;
	CountColors = -1;
	while (ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
	{
		/*len = strlen(sBuffer);
		if (sBuffer[len-1] == '\n')
			sBuffer[--len] = '\0';*/

		TrimString(sBuffer);

		if(!StrEqual(sBuffer,"",false)){
			
			ReplaceString(sBuffer, sizeof(sBuffer), "*", "\x08");
			ReplaceString(sBuffer, sizeof(sBuffer), "&", "\x07");
			CountColors++;
			Format(TextColors[CountColors], sizeof(TextColors), "%s", sBuffer);
			PrintToChatAll("\x01%s", sBuffer);
		}
	}
	CloseHandle(hFile);
}
public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(CountColors != -1)
	{
		if(reliable)
		{
			new String:buffer[256];
			BfReadString(bf, buffer, sizeof(buffer));
			if(StrContains(buffer, "\x03[SM]") == 0)
			{
				new Handle:pack;
				CreateDataTimer(0.0, timer_strip, pack);

				WritePackCell(pack, playersNum);
				for(new i = 0; i < playersNum; i++)
				{
					WritePackCell(pack, players[i]);
				}
				WritePackString(pack, buffer);
				ResetPack(pack);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action:timer_strip(Handle:timer, Handle:pack)
{
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
	
	new String:buffer[255];
	ReadPackString(pack, buffer, sizeof(buffer));
	new String:QuickFormat[255];
	new ColorChoose = 0;
	if(UseRandomColors == 1) ColorChoose = GetRandomInt(0, CountColors);
	Format(QuickFormat, sizeof(QuickFormat), "%s", TextColors[ColorChoose]);
	ReplaceStringEx(buffer, sizeof(buffer), "[SM]", QuickFormat);
	
	new Handle:bf = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	//BfWriteString(bf, buffer);
	BfWriteByte(bf, -1);
	BfWriteByte(bf, true);
	BfWriteString(bf, buffer);
	EndMessage();
}