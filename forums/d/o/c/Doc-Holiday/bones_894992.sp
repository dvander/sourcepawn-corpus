#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib/clients>
#include <cssdroppedammo>
#include <weaponsystem>
#include <sdkhooks>


new const String:PLUGIN_VERSION[] = "3.1.3";
const MAX_CLIENT_WEAPONS = 5;

public Plugin:myinfo = 
{
	name = "Bones Source",
	author = "SavSin",
	description = "Armed with only a knife. If you want to survive you'll need to kill the enemy and steal their weapons.",
	version = PLUGIN_VERSION,
	url = "http://www.NorCalBots.com"
}

/*Data Handlers*/
new bool:g_bIsRoundOver;
new bool:g_bHasBombZone;
new bool:g_bHasDied[MAXPLAYERS+1];
new Float:g_flOrigin[MAXPLAYERS+1][3];
new String:ClientWeapons[MAXPLAYERS + 1][MAX_CLIENT_WEAPONS][MAX_WEAPON_STRING];

/*Plugin Cvars */
new Handle:g_Cvar_KnifeDmgMulti = INVALID_HANDLE;
new Handle:g_Cvar_GiveDefuser = INVALID_HANDLE;
new Handle:g_Cvar_GiveArmor = INVALID_HANDLE;
new Handle:g_Cvar_ArmorAmount = INVALID_HANDLE;
new Handle:g_Cvar_GiveHelmet = INVALID_HANDLE;
new Handle:g_Cvar_DropAllWeapons = INVALID_HANDLE;

/*Weapon Variables*/
new Handle:g_WeaponArray[2] = INVALID_HANDLE;
new String:g_szWeaponFile[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	CreateConVar("Bones_Version", PLUGIN_VERSION, "Version of bones source", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_reload_weapons", CMD_ReloadWeaponList, ADMFLAG_BAN, "Reloads weapon lists");
	
	g_Cvar_KnifeDmgMulti = CreateConVar("sm_bones_knifedmgmulti", "2", "Amount to multiply damage of the knife. <Default: 2>");
	g_Cvar_GiveDefuser = CreateConVar("sm_bones_givedefuser", "1", "Give Defuse Kits? <Default: 1>");
	g_Cvar_GiveArmor = CreateConVar("sm_bones_givearmor", "0", "Give Armor to Humans? <Default: 0>");
	g_Cvar_ArmorAmount = CreateConVar("sm_bones_armoramt", "100", "How Much Armor? <Default: 100>");
	g_Cvar_GiveHelmet = CreateConVar("sm_bones_givehelm", "1", "Give Helmet? <Default: 1>");
	g_Cvar_DropAllWeapons = CreateConVar("sm_bones_dropall", "1", "Drop all weapons? <Default: 1>");
	
	decl String:szGameDir[PLATFORM_MAX_PATH];
	GetGameFolderName(szGameDir, sizeof(szGameDir));
	if(strcmp(szGameDir, "cstrike") != 0 && strcmp(szGameDir, "csgo") != 0)
	{
		SetFailState("Error: %s is unsupported.", szGameDir);
	}
	else if(strcmp(szGameDir, "cstrike") == 0)
	{
		//CSS Weapon File
		strcopy(g_szWeaponFile, sizeof(g_szWeaponFile), "cfg/bones/css/cssWeaponsList.ini");
	}
	else
	{
		//CSGO Weapon File
		strcopy(g_szWeaponFile, sizeof(g_szWeaponFile), "cfg/bones/csgo/csgoWeaponsList.ini");
	}
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);
}

public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(iClient)
{
	ClearClientWeapons(iClient);
	SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:CMD_ReloadWeaponList(iClient, iArgs)
{
	LoadWeaponsArrays();
	ReplyToCommand(iClient, "Weapon List has been Reloaded");
}

public OnMapStart()
{
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "func_buyzone")) != -1)
	{
		AcceptEntityInput(ent, "Kill");
	}
	
	ent = -1;
	if((FindEntityByClassname(ent, "func_bomb_target")) != -1)
	{
		g_bHasBombZone = true;
	}
	
	if(FileExists(g_szWeaponFile))
	{
		LoadWeaponsArrays();
	}
	else
	{
		SetFailState("Weapon File not found. Check: %s", g_szWeaponFile);
	}
}

public Action:Event_PlayerTeam(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent,"userid"));
	//new iNewTeam = GetEventInt(hEvent,"team");
	//new iOldTeam = GetEventInt(hEvent,"oldteam");
	new bDisconnect = GetEventBool(hEvent, "disconnect");
	
	if(!bDisconnect)
	{
		/*if(iOldTeam == CS_TEAM_SPECTATOR)*/
		g_bHasDied[iClient] = true;
	}
}

public Action:CS_OnCSWeaponDrop (iClient, iWeapon)
{
	if(g_bIsRoundOver)
	{
		PrintHintText(iClient, "Weapons can not be dropped after round end!");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public LoadWeaponsArrays()
{
	new String:szBuffer[128], WeaponSlot:iWeaponSlot;
	g_WeaponArray[0] = CreateArray(32);
	g_WeaponArray[1] = CreateArray(32);
	new iArrayIndex[2];
	new Handle:WeaponList = OpenFile(g_szWeaponFile, "r");		
	
	while(ReadFileLine(WeaponList, szBuffer, sizeof(szBuffer)))
	{
		if(!ParseLineOfText(szBuffer, true))
			continue;
		
		Format(szBuffer, sizeof(szBuffer), "weapon_%s", szBuffer);
		iWeaponSlot = GetWeaponSlot(szBuffer);
		iArrayIndex[iWeaponSlot] = PushArrayString(g_WeaponArray[iWeaponSlot], szBuffer);
	}
	LogMessage("Loaded %d primary and %d secondary weapons from file.", iArrayIndex[0], iArrayIndex[1]);
	CloseHandle(WeaponList);
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent,"userid"));
	
	if(!IsClientInGame(iClient) && !IsPlayerAlive(iClient))
		return Plugin_Continue;
	
	new String:szPRandomWeapon[32], String:szSRandomWeapon[32];
	
	if(g_bHasDied[iClient])
		StripUserWeapons(iClient, true);
	else
		RestoreClientWeapons(iClient);
		
	if(IsFakeClient(iClient))
	{		
		new iRandomPrimaryWeapon = GetRandomInt(0, (GetArraySize(g_WeaponArray[0]) - 1));
		new iRandomSecondaryWeapon = GetRandomInt(0, (GetArraySize(g_WeaponArray[1]) - 1));
		
		StripUserWeapons(iClient, true);
		
		GetArrayString(g_WeaponArray[0], iRandomPrimaryWeapon, szPRandomWeapon, sizeof(szPRandomWeapon));
		GetArrayString(g_WeaponArray[1], iRandomSecondaryWeapon, szSRandomWeapon, sizeof(szSRandomWeapon));
		
		GivePlayerItem(iClient, szPRandomWeapon);
		GivePlayerItem(iClient, szSRandomWeapon);
	}
	
	if(GetConVarInt(g_Cvar_GiveArmor) || IsFakeClient(iClient))
	{
		SetEntProp(iClient, Prop_Send, "m_ArmorValue", GetConVarInt(g_Cvar_ArmorAmount));
		SetEntProp(iClient, Prop_Send, "m_bHasHelmet", GetConVarInt(g_Cvar_GiveHelmet));
	}
	
	if(g_bHasBombZone && GetClientTeam(iClient) == CS_TEAM_CT && !GetEntProp(iClient, Prop_Send, "m_bHasDefuser") && ((GetConVarInt(g_Cvar_GiveDefuser) || IsFakeClient(iClient))))
	{
		SetEntProp(iClient, Prop_Send, "m_bHasDefuser", 1);
	}
	
	g_bHasDied[iClient] = false;
	
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	new iVictimHealth = GetClientHealth(iVictim);
	if (iVictimHealth <= 0)
	{
		SaveClientWeapons(iVictim);
		if(GetConVarInt(g_Cvar_DropAllWeapons))
			StripUserWeapons(iVictim, false);
	}
}

public Action:OnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:flDamage, &iDamageType)
{
	if(1 <= iAttacker <= MaxClients)
	{		
		new String:szWeapon[32];
		GetClientWeapon(iAttacker, szWeapon, sizeof(szWeapon));
		
		if(GetWeaponID(szWeapon) == WEAPON_KNIFE)
		{
			flDamage *= GetConVarFloat(g_Cvar_KnifeDmgMulti);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));	
	if(GetConVarInt(g_Cvar_DropAllWeapons))
		CreateDroppedWeapons(iVictim);
		
	g_bHasDied[iVictim] = true;
	ClearClientWeapons(iVictim);
}

public Action:Event_RoundStart(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	g_bIsRoundOver = false;
}

public Action:Event_RoundEnd(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	g_bIsRoundOver = true;
	
	for(new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
		{
			g_bHasDied[iClient] = false;
			SaveClientWeapons(iClient);
			SetEntProp(iClient, Prop_Send, "m_bIsDefusing", 1);
		}
	}
}

stock StripUserWeapons(iClient, bool:bResetKnife)
{
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		new iPrimaryWeapon = GetPlayerWeaponSlot(iClient, 0);
		new iSecondaryWeapon = GetPlayerWeaponSlot(iClient, 1);
		
		if(iPrimaryWeapon != -1)
			RemovePlayerItem(iClient, iPrimaryWeapon);
			
		if(iSecondaryWeapon != -1)
			RemovePlayerItem(iClient, iSecondaryWeapon);
		
		if(bResetKnife)		
		{
			new iKnifeSlot = GetPlayerWeaponSlot(iClient, 2);
			
			if(iKnifeSlot != -1)
				RemovePlayerItem(iClient, iKnifeSlot);
				
			GivePlayerItem(iClient, "weapon_knife");
		}
	}
}

stock SaveClientWeapons(const iClient)
{
	new weapon;
	decl String:weaponclassname[MAX_WEAPON_STRING];
	new j = 0;
	for (new i = 0, offset = Client_GetWeaponsOffset(iClient); i < MAX_WEAPONS; i++, offset += 4)
	{
		weapon = GetEntDataEnt2(iClient, offset);
		if (!Weapon_IsValid(weapon))
		{
			break;
		}
		GetEdictClassname(weapon, weaponclassname, MAX_WEAPON_STRING);
		if ((!StrEqual(weaponclassname, "weapon_knife")) && (!StrEqual(weaponclassname, "weapon_c4")))
		{
			strcopy(ClientWeapons[iClient][j], MAX_WEAPON_STRING, weaponclassname);
			j++;
			if (j == MAX_CLIENT_WEAPONS)
			{
				return;
			}
		}
	}
	GetEntPropVector(iClient, Prop_Data, "m_vecOrigin", g_flOrigin[iClient]);
	ClientWeapons[iClient][j][0] = '\0';
}

stock RestoreClientWeapons(const iClient)
{
	StripUserWeapons(iClient, false);
	
	for (new i = 0; i < MAX_CLIENT_WEAPONS; i++)
	{
		if (ClientWeapons[iClient][i][0] == '\0')
		{
			continue;
		}
		GivePlayerItem(iClient, ClientWeapons[iClient][i]);
	}
}

stock ClearClientWeapons(const iClient)
{
	for (new i = 0; i < MAX_CLIENT_WEAPONS; i++)
	{
		ClientWeapons[iClient][i][0] = '\0';
	}
}

stock CreateDroppedWeapons(const iClient)
{
	decl iEnt;
	for (new i = 0; i < MAX_CLIENT_WEAPONS; i++)
	{
		if((iEnt = CreateEntityByName(ClientWeapons[iClient][i])) != -1)
		{
			DispatchSpawn(iEnt);
			CS_SetDroppedWeaponAmmo(iEnt, GetMaxWeaponAmmo(ClientWeapons[iClient][i]));
			TeleportEntity(iEnt, g_flOrigin[iClient], NULL_VECTOR, NULL_VECTOR);
		}
	}
	ClearClientWeapons(iClient);
}

stock bool:ParseLineOfText(String:szString[], bool:bStripQuotes)
{
	if((szString[0] == '/' && szString[1] == '/') //Check for // type comment
	|| szString[0] == ';' //check for ; type comment
	|| strlen(szString) <= 2 //Make sure its not just a blank line
	|| IsCharSpace(szString[0])) //checks for a space as the first character.
		return false;
		
	TrimString(szString); //remove the new line characters.
	
	if(bStripQuotes)
		StripQuotes(szString); //Strip the quotes from the file.
	
	return true;
}