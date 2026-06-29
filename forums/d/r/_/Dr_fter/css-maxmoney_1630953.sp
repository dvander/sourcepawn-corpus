#include <sourcemod>
#pragma semicolon 1

#define MAXMATCHES 10

new Address:AddAccountAddr;
new Address:maxmoney[MAXMATCHES] = {Address_Null, ...};
new matches = 0;
new Handle:mp_maxmoney = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[CS:S]MaxMoney",
	author = "Dr!fter",
	description = "Patches max money",
	version = "1.0.3"
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:gamedir[PLATFORM_MAX_PATH];
	GetGameFolderName(gamedir, sizeof(gamedir));
	if(strcmp(gamedir, "cstrike") != 0)
	{
		strcopy(error, err_max, "This plugin is only supported on CS:S");
		return APLRes_Failure;
	}
	return APLRes_Success;
}
public OnPluginStart()
{
	SetConVarBounds(FindConVar("mp_startmoney"), ConVarBound_Upper, false);
	SetConVarBounds(FindConVar("mp_startmoney"), ConVarBound_Lower, false);
	
	mp_maxmoney = CreateConVar("mp_maxmoney", "65000", "Set's max money limit", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED);
	HookConVarChange(mp_maxmoney, MaxMoneyChange);
	
	new Handle:gameconf = LoadGameConfigFile("maxmoney.games");
	if(gameconf == INVALID_HANDLE)
		SetFailState("Failed to load gamedata maxmoney.games.txt");
	
	AddAccountAddr = GameConfGetAddress(gameconf, "AddAccount");
	
	if(!AddAccountAddr)
		SetFailState("Failed to get AddAccount address");
	
	new len = GameConfGetOffset(gameconf, "AddAccountLen");
	
	for(new i = 0; i <= len; i++)
	{
		if(LoadFromAddress(AddAccountAddr+Address:i, NumberType_Int32) == 16000 && matches < MAXMATCHES)
		{
			maxmoney[matches] = AddAccountAddr+Address:i;
			matches++;
		}
	}
	PatchMoney();
	
	CloseHandle(gameconf);
}
public MaxMoneyChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	PatchMoney();
}
public OnPluginEnd()
{
	for(new i = 0; i < matches; i++)
	{
		StoreToAddress(maxmoney[i], 16000, NumberType_Int32);
		maxmoney[i] = Address_Null;
	}
}
PatchMoney()
{	
	new money = GetConVarInt(mp_maxmoney);
	
	for(new i = 0; i < matches; i++)
	{
		StoreToAddress(maxmoney[i], money, NumberType_Int32);
	}
}