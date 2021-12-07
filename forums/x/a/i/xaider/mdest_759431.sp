#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.08"

#define YELLOW               0x01
#define NAME_TEAMCOLOR       0x02
#define TEAMCOLOR            0x03
#define GREEN                0x04 

public Plugin:myinfo =
{
	name = "Most destructive",
	author = "X@IDER",
	description = "Show most dsestructive player at end of round",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

// Arrays
new GDamage[65],GPlayers[65],GHits[65];

// Cvars
new Handle:sm_most_damage_mode = INVALID_HANDLE;
new Handle:sm_most_damage_lines = INVALID_HANDLE;

new String:DmgParam[16] = "dmg_health";	// cstrike, l4d, insurgency

public OnPluginStart()
{
	LoadTranslations("plugin.mdest");

	sm_most_damage_mode = CreateConVar("sm_md_mode", "0", "0 - display in chat, 1 - in hint", 0);
	sm_most_damage_lines = CreateConVar("sm_md_lines", "3", "0 - none, 1 - most damage, 2 - most kills, 3 - both", 0);
	
	HookEvent("round_start", Round_Start, EventHookMode_PostNoCopy);
	HookEvent("round_end", Round_End, EventHookMode_PostNoCopy);
	HookEvent("player_hurt", Damage, EventHookMode_Post);
	HookEvent("player_death", Death, EventHookMode_Post);
	
	new String:GameDir[32];
	GetGameFolderName(GameDir,32);
	
	if (!strcmp(GameDir,"dod")) DmgParam = "damage";
}

public SayText2(to, from, const String:format[], any:...)
{
	decl String:message[256];
	VFormat(message,sizeof(message),format,4);
	
	new Handle:hBf = StartMessageOne("SayText2", to);
	BfWriteByte(hBf, from);
	BfWriteByte(hBf, true);
	BfWriteString(hBf, message);
	
	EndMessage();
}

public Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new t = GetClientOfUserId(GetEventInt(event,"attacker"));
	if (t) GPlayers[t]++;
}

public Damage(Handle:event, const String:name[], bool:dontBroadcast)
{
	new t = GetClientOfUserId(GetEventInt(event,"attacker"));	
	if (t) 
	{
		GDamage[t] += GetEventInt(event,DmgParam);
		GHits[t]++;
	}
}

public Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	GDamage[i] = GPlayers[i] = GHits[i] = 0;
}

public Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	new maxGD = 0,maxGP = 0;
	GDamage[0] = GPlayers[0] = GHits[0] = 0;

	new String:nameGD[32],String:nameGP[32];

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{
		if (GDamage[i] > GDamage[maxGD]) maxGD = i;
		else if ((GDamage[i] == GDamage[maxGD]) && (GPlayers[i] > GPlayers[maxGD])) maxGD = i;
		if (GPlayers[i] > GPlayers[maxGP]) maxGP = i;
		else if ((GDamage[i] > GDamage[maxGP]) && (GPlayers[i] == GPlayers[maxGP])) maxGP = i;
	}

	GetClientName(maxGD,nameGD,31);
	GetClientName(maxGP,nameGP,31);

	new lines = GetConVarInt(sm_most_damage_lines);

	if (GetConVarBool(sm_most_damage_mode))
	{
		decl String:buff[512],String:line[512];
		buff[0] = 0;
		if (maxGD && (lines & 1))
		{
			Format(line,512,"%t","Max damage",nameGD,GDamage[maxGD],GPlayers[maxGD],GHits[maxGD]);
			StrCat(buff,512,line);
		}
		if (maxGD && maxGP && (lines == 3)) StrCat(buff,512,"\n");
		if (maxGP && (lines & 2))
		{
			Format(line,512,"%t","Max kills",nameGP,GDamage[maxGP],GPlayers[maxGP],GHits[maxGP]);
			StrCat(buff,512,line);
		}
		if (buff[0]) PrintHintTextToAll(buff);
	} else
	{
		for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (maxGD && (lines & 1)) SayText2(i,maxGD,"%t","Maximum damage",YELLOW,TEAMCOLOR,nameGD,YELLOW,GREEN,GDamage[maxGD],YELLOW,GREEN,GPlayers[maxGD],YELLOW,GREEN,GHits[maxGD],YELLOW);
			if (maxGP && (lines & 2)) SayText2(i,maxGP,"%t","Maximum kills",YELLOW,TEAMCOLOR,nameGP,YELLOW,GREEN,GDamage[maxGP],YELLOW,GREEN,GPlayers[maxGP],YELLOW,GREEN,GHits[maxGP],YELLOW);
		}
	}
}
